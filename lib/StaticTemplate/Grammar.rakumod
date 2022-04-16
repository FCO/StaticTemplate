#use Grammar::Tracer;
use StaticTemplate::Stack;
unit grammar StaticTemplate::Grammar;

method error($msg, :$comment) {
  my $pos = $*starting-error // self.pos;
  my $parsed-so-far = self.target.substr(0, $pos);
  my $break = $pos + 15;
  with self.target.index("\n", $pos) {
    $break min= $_ - $pos
  }
  my $not-parsed = self.target.substr: $pos, $break;
  my @lines = $parsed-so-far.lines;
  note "\nCompiling ERROR on line @lines.elems():\n";
  note "$msg: { "\o033[32m@lines[*-1].trim-leading()\o033[33m⏏" if @lines }{ "({ $comment })" with $comment }\o033[31m$not-parsed\o033[m";
  exit 1;
}

token TOP {
  <multi-template(StaticTemplate::Stack)>
}
token multi-template($scope) {
  :my $*scope := $scope.new-scope;
  <template>*
}

proto token template {*}
token template:sym<text> { <text> }
token template:sym<code> { <code> }

token text { [<!start-code>.]+ }

proto rule code {*}
rule code:sym<val> {
  <start-val> ~ <end-val> <statement>+ %% ";"
}

token block-tag($name) {
  <.start-block> ~ <.end-block> [ <.ws> $name <.ws> ] <?>
}

rule closing-block-tag($name) {
  <block-tag($name)> || $ { self.error: "Could not find '\{% $name %}' closing tag", :comment("never closing tag") }
}

rule code:sym<if> {
  <.start-block> ~ <.end-block> [ "if" <condition=.statement> ]
  {}
  :my $*starting-error := $/.pos;
  <if-block=multi-template($*scope)>+ % [ <.start-block> ~ <.end-block> [ "elsif" <condition=.statement> ] ]
  [ <.start-block> ~ <.end-block> "else" <else-block=.multi-template($*scope)> ]?
  <.closing-block-tag("endif")>
}

rule code:sym<set> {
  <.start-block> ~ <.end-block> [ "set" <var-name=.word> ]
  { $*scope.define: $<var-name>.Str }
  <initial-value=.multi-template($*scope)>
  <.closing-block-tag("endset")>
}

rule code:sym<set-eq> {
  <.start-block> ~ <.end-block> [
    "set" <var-name=.word>
    "="
    <initial-value=.statement>
  ]
  { $*scope.define: $<var-name>.Str }
}

rule end-raw {
  <.block-tag("endraw")>
}

token code:sym<raw> {
  <.block-tag("raw")>
  {}
  :my $*starting-error := $/.pos;
  $<text>=[[<!end-raw>.]*]
  <.closing-block-tag("endraw")>
}

rule code:sym<test> {
  [<.start-block> ~ <.end-block> \w+] ~ [<.start-block> ~ <.end-block> \w+] \w*
}

token word { \w+ }

proto rule statement {*}
token statement:sym<variable> { <variable> }
rule statement:sym<value> { <value> }
#rule statement:sym<word> { <word> }
rule statement:sym<error> { <error("Variable or function not recognised")> }

token start-block { '{%' }
token start-val   { '{{' }
token end-block   { '%}' }
token end-val     { '}}' }

proto token start-code {*}
token start-code:sym<block> { <.start-block> }
token start-code:sym<val> { <.start-val> }

proto token end-code {*}
token end-code:sym<block> { <.end-block> }
token end-code:sym<val> { <.end-val> }

token number { <[+-]>? [\d*\.]? \d+ }

proto token value {*}
token value:sym<operation> { <term-op1> }
token value:sym<number> { <number> }

token dbl-quote { \" }
token single-quote { \' }
token escaped-dbl-quote { '\"' }
token escaped-single-quote { "\\'" }

token value:sym<dstr> { <dbl-quote> ~ <dbl-quote> $<str>=[<escaped-dbl-quote>|<-["]>]* }
token value:sym<sstr> { <single-quote> ~ <single-quote> $<str>=[<escaped-single-quote>|<-[']>]* }

proto token op1 {*}
token op1:sym<+> { <sym> }
token op1:sym<-> { <sym> }

proto token op2 {*}
token op2:sym<*> { <sym> }
token op2:sym</> { <sym> }

token variable { <{ $*scope.all-variables }> }

token factor { <number> | <variable> }
rule term-op2 { <factor>+ %% [ <.ws> <op2> <.ws> ] }
rule term-op1 { <term-op2>+ %% [ <.ws> <op1> <.ws> ] }

