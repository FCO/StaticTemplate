unit class StaticTemplate::AST::If;

has @.conditions;
has $.else;

method gist {
  [
    "{ $?CLASS.^name }:",
    |do for @!conditions -> (:$key, :@value) {
      |(
        "condition:".indent(2),
        $key.gist.indent(4),
        "block:".indent(2),
        |@value».gist».indent(4),
      )
    },
    |(
      do with $!else {
        "else:".indent(2),
        $!else.gist.indent(4),
      }
    )
  ].join: "\n"
}

method run {
  # TODO: make it a real if
  @!conditions.first.value.run()
}
