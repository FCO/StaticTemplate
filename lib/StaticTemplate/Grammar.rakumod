#use Grammar::Tracer;
use StaticTemplate::Stack;
use StaticTemplate::Type;
use X::StaticTemplate::CompileError;
unit grammar StaticTemplate::Grammar;

method error($msg, :$comment, :$tag) {
  my ($pos, $break) = do with $tag {
    my $pos = $tag.pos;
    my $break = $tag.pos + 15;

    $pos,
    $break,
  } else {
    my $pos = self.pos;
    my $break = $pos + 15;

    $pos,
    $break,
  }

  with self.target.index("\n", $pos) {
    $break min= $_ - $pos
  }

  my Str $not-parsed = self.target.substr: $pos, $break;
  my $parsed-so-far  = self.target.substr(0, $pos);
  my UInt $line      = $parsed-so-far.lines.elems;
  my Str $last-line  = $parsed-so-far.lines[*-1];

  X::StaticTemplate::CompileError.new(
    :$line,
    :$msg,
    :$comment,
    :$last-line,
    :$not-parsed,
  ).throw;
}

my %types = <any number string boolean array object>.map: { $_ => StaticTemplate::Type.type($_) }

token TOP {
  <multi-template(StaticTemplate::Stack, %types)>
}

token wanted-types { <list-of-wanted-types> }

regex list-of-wanted-types { <wanted-type>+ %% "|" }

regex wanted-type          {
  [
    $<base>=[
      \w+ [
        "[" ~ "]" <sub-types=.list-of-wanted-types>+
      ]?
      | "enum(" ~ ")" .*?
    ]
  ]
}

token multi-template($scope, %types) {
  :my $*scope := $scope.new-scope;
  :my %*types := %types;
  <template>*
}

proto token template {*}
token template:sym<text> { <text> }
token template:sym<code> { <code> }

token text { [<!start-code>.]+ }

rule type {
  <{ %*types.keys }> "[" ~ "]" <of=~~>
}

proto rule code {*}
rule code:sym<val> {
  <.start-val> ~ <.end-val> <statement>+ %% ";"
}

token block-tag($name) {
  <.start-block> ~ <.end-block> [ <.ws> $name <.ws> ] <?>
}

rule closing-block-tag($name, $tag) {
  || <block-tag("end$name")>
  || $ <error("Could not find '\o033[1m\{% end$name %}\o033[m' closing for tag '\o033[1m$tag.Str()\o033[m'", :comment("never closing tag"), :$tag)>
}

token code:sym<if> {
  $<tag>=[ <.start-block> ~ <.end-block> [ <.ws> <sym> <.ws> <condition=.statement> <.ws> ] ]
  <if-block=multi-template($*scope, %*types)>+ % [ <.start-block> ~ <.end-block> [ <.ws> "elsif" <.ws> <condition=.statement> <.ws> ] ]
  [ <.start-block> ~ <.end-block> [ <.ws> "else" <.ws> ] <else-block=.multi-template($*scope, %*types)> ]?
  <.closing-block-tag("if", $<tag>)>
}

token code:sym<set> {
  $<tag>=[ <.start-block> ~ <.end-block> [ <.ws> <sym> <.ws> <var-name=.word> <.ws> ] ]
  {}
  { $*scope.define: $<var-name>.Str }
  <initial-value=.multi-template($*scope, %*types)>
  <.closing-block-tag("set", $<tag>)>
}

rule code:sym<set-eq> {
  <.start-block> ~ <.end-block> [
    "set" <var-name=.word>
    "="
    <initial-value=.statement>
  ]
  { $*scope.define: $<var-name>.Str }
}

token code:sym<macro> {
  $<tag>=[
      <.start-block> ~ <.end-block> [
      <.ws> <sym> <.ws>
      <macro-name=.word>
      <signature>
      <.ws>
    ]
  ]
  <block=.multi-template($*scope, %*types)>
  { $*scope.define: $<macro-name>.Str }
  <.closing-block-tag("macro", $<tag>)>
}

proto rule param {*}
rule param:sym<positional> {
  <wanted-types>? <var-name=.word> $<optional>=<[?!]>? [ "=" <default=.statement> ]?
}
rule param:sym<named> {
  <arg-name=word>":" <wanted-types>? <var-name=.word> $<optional>=<[?!]>? [ "=" <default=.statement> ]?
}
rule param:sym<homonamed> {
  <wanted-types>? ":"<var-name=.word> $<optional>=<[?!]>? [ "=" <default=.statement> ]?
}

rule signature {
  '(' ~ ')' <param>* %% ","
}

rule end-raw {
  <.block-tag("endraw")>
}

token code:sym<raw> {
  <tag=.block-tag("raw")>
  {}
  $<text>=[[<!end-raw>.]*]
  <.closing-block-tag("raw", $<tag>)>
}

rule code:sym<test> {
  [<.start-block> ~ <.end-block> \w+] ~ [<.start-block> ~ <.end-block> \w+] \w*
}

token word { \w+ }

proto rule statement {*}
rule statement:sym<value> { <value> }
#token statement:sym<variable> { <variable> }
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
token value:sym<comparation> { <term-op1>+ %% [ <.ws> <cmp-op> <.ws> ] }
token value:sym<operation> { <term-op1> }
token value:sym<number> { <number> }
token value:sym<true> { <sym> }
token value:sym<false> { <sym> }
token value:sym<dstr> { <dbl-quote> ~ <dbl-quote> $<str>=[<escaped-dbl-quote>|<-["]>]* }
token value:sym<sstr> { <single-quote> ~ <single-quote> $<str>=[<escaped-single-quote>|<-[']>]* }

token dbl-quote { \" }
token single-quote { \' }
token escaped-dbl-quote { '\"' }
token escaped-single-quote { "\\'" }

proto token cmp-op {*}
token cmp-op:sym<==> { <sym> }

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

