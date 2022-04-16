use StaticTemplate::Grammar;
use StaticTemplate::Action;

unit class StaticTemplate::Parser;

method parse-file($file) {
  StaticTemplate::Grammar.parse-file: $file, :actions(StaticTemplate::Action)
}
