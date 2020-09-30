Default-Parameter = syntax {name: Atom, type: ?Type, value: Expr}
Multiple-Parameters = syntax {name: [Atom], type: ?Type}
Parameter = Default-Parameter | Multiple-Parameters
Parameter-List = {groups: [[Parameter]]}
Function-Type = {params: Parameter-List, result: Type}

default-parameter = syntax Default-Parameter(
	[ [var name Atom] [maybe ':' [var type Type]] '=' [var value Expr] ])

multiple-parameters = syntax Multiple-Parameters([ [some [var name Atom]] [maybe ':' [var type Type]] ])

parameter = syntax Parameter([ [either [rule default-parameter] [rule multiple-parameters]] ])

parameter-list = syntax Parameter-List([ '(' [any-sep [any-sep [rule parameter] ','] ';'] ')' ])

function-type = syntax Function-Type([ '(' [rule parameter-list] ')' '->' [var result Type] ])

apply = syntax Apply([ [var func Expr] '(' [any-sep [rule argument] ','] ')' ])
