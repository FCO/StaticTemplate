unit class X::StaticTemplate::CompileError is Exception;

has UInt $.line is required;
has Str  $.msg  is required;
has Str  $.comment;
has Str  $.last-line;
has Str  $.not-parsed;

method message {
  [
    "\o033[31;1mCompiling ERROR\o033[m on line $!line:",
    "$!msg: {
      "\o033[32;1m$!last-line.trim-leading()\o033[33;1m⏏" if $!last-line
    }{
      "({ $!comment })" with $!comment
    }\o033[31;1m$!not-parsed\o033[m";
  ].join: "\n"
}
