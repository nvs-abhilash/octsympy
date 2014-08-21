function A = extractblock(out)
%private function
%note: only parses the first <output_block> (I think).  No
%particular reason it could not do more than one.

  % Parse xml (no xmlread in octave and this is probably faster)
  % this regexp creates pairs like {<tag> "text after tag"}
  Z = regexp(out, '(<[^<>]*>)([^<>]*)' ,'tokens');

  % Now we have some code that crawls over those pairs and creates
  % the octave objects.
  i = 1;
  [i, A] = helper(Z, i, false);
  % assert (i == length(B)), no; might be other stuff or another block
end


function [i, A] = helper(data, i, inblock)
  initem = false;
  A = {};
  while (1)
    switch data{i}{1}
      case '<output_block>'
        inblock = true;
      case '</output_block>'
        assert(inblock);
        return
      case '<f>'
        assert (inblock)
        assert (initem)
        item{length(item)+1} = data{i}{2};
      case '<f/>'
        assert (inblock)
        assert (initem)
        item{length(item)+1} = [];
      case '</f>'
        assert (inblock)
        assert (initem)
      case '<item>'
        % next fields are for the item
        assert (inblock)
        assert (~initem)
        item = {};
        initem = true;
      case '</item>'
        assert (inblock)
        assert (initem)
        %A = [A {item}];
        temp = process_item(item);
        %A{length(A)+1} = item;
        A{length(A)+1} = temp;
        initem = false;

      case '<list>'
        %disp('down into list')
        [i, List] = helper(data, i+1, inblock);
        if initem
          item{length(item)+1} = List;
        else
          A{length(A)+1} = List;
        end
      case '<list/>'
        List = {};
        if initem
          item{length(item)+1} = List;
        else
          A{length(A)+1} = List;
        end

      case '</list>'
        assert (inblock)
        return

      otherwise
        %if strcmpi(data{i}{1}(1:5), '<?xml')
        %  assert(~inblock)
        %  % just skip it
        %else
          warning('whut?')
          data{i}
          %end
    end
    i = i + 1;
    % FIXME: need some check if we hit the end before we find end tag
  end
end


function r = process_item(item)
% process each item and return octave objects

  % this table must match the python code!
  OCTCODE_ERROR = 9999;
  OCTCODE_INT = 1001;
  OCTCODE_DOUBLE = 1002;
  OCTCODE_STR = 1003;
  OCTCODE_USTR = 1004;
  OCTCODE_BOOL = 1005;
  OCTCODE_DICT = 1010;
  OCTCODE_SYM = 1020;

  C = item;
  M = length(C) - 1;
  a = C{1};
  wh = str2double(a);
  assert (~isnan(wh))
  switch wh
    case OCTCODE_INT
      assert(M == 1)
      r = str2double(C{2});
    case OCTCODE_DOUBLE
      assert(M == 1)
      r = hex2num(C{2});
    case OCTCODE_STR
      assert(M == 1)
      % did we escape all strings?
      if (isempty(C{2}))
        r = '';
      else
        r = str_post_xml_filter(C{2});
      end

    case OCTCODE_USTR
      assert(M == 1)
      % FIXME: Extra printf...?  doc
      %newl = sprintf('\n');
      %r = strrep(C{2}, '\n', newl);
      r = str_post_xml_filter(C{2});

    case OCTCODE_BOOL
      assert(M == 1)
      r = strcmpi(C{2}, 'true');
    case OCTCODE_SYM
      assert(M == 6)
      %warning('FIXME: wip?  more error checking')
      sz1 = str2double(C{3});
      sz2 = str2double(C{4});
      assert(~isnan(sz1));
      assert(~isnan(sz2));
      % fixme: should we use <item>'s for these not raw <f>?
      str = str_post_xml_filter(C{2});
      flat = str_post_xml_filter(C{5});
      ascii = str_post_xml_filter(C{6});
      unicode = str_post_xml_filter(C{7});
      r = sym(str, [sz1 sz2], flat, ascii, unicode);
    case OCTCODE_DICT
      %warning('FIXME: wip');
      keys = C{2}{1};
      vals = C{3}{1};
      % FIXME: why the {1} here?
      %r = cell2struct(C{2}{1}, C{3}{1})  % no
      assert(length(keys) == length(vals))
      r = struct();
      for i=1:length(keys)
        r = setfield (r, keys{i}, vals{i});
      end
    case OCTCODE_ERROR
      assert(M == 2)
      str1 = str_post_xml_filter(C{2});
      str2 = str_post_xml_filter(C{3});
      warning('extractblock: read an error back from python')
      str1
      str2
      disp('Continuing, but unsure if its safe to do so!')
      r = 'there was a python error';
    otherwise
      C
      error('extractblock: not implemented or something wrong');
  end
end


function r = str_post_xml_filter(r)
  r = strrep(r, '&lt;', '<');
  r = strrep(r, '&gt;', '>');
  r = strrep(r, '&quot;', '"');
  % must be last:
  r = strrep(r, '&amp;', '&');
end
