use StaticTemplate::WantedType;
unit class StaticTemplate::AST::Param;

has Bool                       $.named = False;
has Str                        $.var-name;
has Str                        $.arg-name = $!var-name;
has                            $.default;
has StaticTemplate::WantedType $.wanted-types;
has Bool                       $.optional;
has Str                        $.doc;

submethod BUILD(Bool :$!named, Str :$!var-name, Str :$!arg-name, :$!default, :$wanted-types = "any", :$!optional = False, :$!doc = "") {
  if $wanted-types ~~ Str {
    $!wanted-types .= new: :name($wanted-types)
  } else {
    $!wanted-types = $wanted-types
  }
}

method gist {
  [
    "{ $?CLASS.^name}:",
    "var-name:".indent(2),
    $!var-name.indent(4),
    |(
      "arg-name:".indent(2),
      $!arg-name.indent(4),
      if $!named
    ),
    "default:".indent(2),
    $!default.gist.indent(4),
    "wanted-types: $!wanted-types.name()".indent(2),
    |("optional".indent(2) if $!optional),
    "doc:".indent(2),
    $!doc.indent(4),
  ].join: "\n"
}

method run {
  #%*SCOPE{ $!name } = .run with $!default;
  ""
}

