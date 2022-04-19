use StaticTemplate::Grammar;
use StaticTemplate::Action;
use X::StaticTemplate::CompileError;

unit class StaticTemplate::Parser;

method parse-file($file) {
  my $match = StaticTemplate::Grammar.parse-file: $file, :actions(StaticTemplate::Action);
  $match.made
}

method parse($file) {
  my $match = StaticTemplate::Grammar.parse: $file, :actions(StaticTemplate::Action);
  $match.made
}
