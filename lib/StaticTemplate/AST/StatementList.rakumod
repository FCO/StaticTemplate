unit class StaticTemplate::AST::StatementList does Positional;

has @.vars;
has @.statements handles *;

method gist {
  [
    "{ $?CLASS.^name }:",
    "variables on scope:".indent(2),
    |@!vars».indent(4),
    |@!statements».gist».indent(2),
  ].join: "\n"
}

method run {
  my %parent-vars;
  for @!vars -> $var {
    %parent-vars{ $var } = $_ with %*SCOPE{ $var };
    %*SCOPE{ $var } = Nil;
  }
  LEAVE %*SCOPE{ $_ } = %parent-vars{ $_ } for %parent-vars.keys;
  @!statements.map(*.run).join
}
