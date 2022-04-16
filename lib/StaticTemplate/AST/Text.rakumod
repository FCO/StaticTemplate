unit class StaticTemplate::AST::Text;

has Str $.text handles *;

method gist {
  [
    "'",
    $!text.subst("\n", "␤", :g),
    "'"
  ].join
}

method run {
  $!text
}
