unit class StaticTemplate::AST::Statement;

has $.data;

method gist {
  "statement:\n$!data.gist().indent(2)"
}
