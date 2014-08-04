%% Copyright (C) 2014 Colin B. Macdonald
%%
%% This file is part of OctSymPy.
%%
%% OctSymPy is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published
%% by the Free Software Foundation; either version 3 of the License,
%% or (at your option) any later version.
%%
%% This software is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty
%% of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
%% the GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public
%% License along with this software; see the file COPYING.
%% If not, see <http://www.gnu.org/licenses/>.

%% Author: Colin B. Macdonald
%% Keywords: symbolic

function t = ineq_helper(op, fop, lhs, rhs, nanspecial)

  if (nargin == 4)
    nanspecial = 'S.false';
  end

  cmd = [ '(lhs, rhs) = _ins\n' ...
          'def scineq(lhs, rhs):\n' ...
          '    # workaround sympy nan behaviour, Issue #9\n' ...
          '    if lhs is nan or rhs is nan:\n' ...
          '        return ' nanspecial '\n' ...
          '    return ' fop '(lhs, rhs)\n' ...
          'if lhs.is_Matrix and rhs.is_Matrix:\n' ...
          '    assert lhs.shape == rhs.shape\n' ...
          '    A = Matrix(lhs.shape[0], lhs.shape[1],\n' ...
          '        lambda i, j: scineq(lhs[i,j], rhs[i,j]))\n' ...
          '    return (A, )\n' ...
          'if lhs.is_Matrix and not rhs.is_Matrix:\n' ...
          '    return (lhs.applyfunc(lambda a: scineq(a, rhs)), )\n' ...
          'if not lhs.is_Matrix and rhs.is_Matrix:\n' ...
          '    return (rhs.applyfunc(lambda a: scineq(lhs, a)), )\n' ...
          'return (scineq(lhs, rhs), )' ];

  t = python_cmd (cmd, sym(lhs), sym(rhs));

end

