unit class StaticTemplate::Signature;

has @.positional;
has %.named;

submethod BUILD(:@!positional, :@named) {
  %!named = @named.map: { .arg-name => $_ }
}

method gist {
  [
    "{ ::?CLASS.^name }:",
    "positional:".indent(2),
    |@!positional.map(*.gist)».indent(4),
    "named:".indent(2),
    |%!named.values.map: {
      .arg-name.indent(4),
      .gist.indent(6),
    },
  ].join: "\n"
}
