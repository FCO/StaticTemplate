use StaticTemplate::AST::If;
use StaticTemplate::AST::Text;
use StaticTemplate::AST::Operation;
use StaticTemplate::AST::Statement;
use StaticTemplate::AST::StatementList;
use StaticTemplate::AST::CompUnit;
use StaticTemplate::AST::Variable;
use StaticTemplate::AST::VariableDeclaration;
use StaticTemplate::Type;
use StaticTemplate::WantedType;
use StaticTemplate::AST::Param;
use StaticTemplate::Signature;

unit class StaticTemplate::Action;

method TOP($/) {
  make StaticTemplate::AST::CompUnit.new: :main($<multi-template>.made)
}

method multi-template($/) {
  make StaticTemplate::AST::StatementList.new:
    :statements($<template>».made),
    :vars($*scope.scope-variables)
}

method template:sym<text>($/) {
  make StaticTemplate::AST::Text.new :text($<text>.Str)
}

method template:sym<code>($/) {
  make $<code>.made
}

method wanted-types($/) {
  StaticTemplate::WantedType.new: $/.Str
}

method text($/) { make $/.Str }

method code:sym<val>($/) {
  make StaticTemplate::AST::StatementList.new:
    :statements($<statement>».made)
}

method word($/) { $/.Str }

method type($/) {
  StaticTemplate::Type.new: $/.Str
}

method statement:sym<value>($/) {
  make $<value>.made
}

method statement:sym<variable>($/) {
  make $<variable>.made
}

# TODO: review
method statement:sym<word>($/) {
  make StaticTemplate::AST::Statement.new: :data($<word>.made)
}

method variable($/) {
  make StaticTemplate::AST::Variable.new: :name($/.Str)
}

method code:sym<if>($/) {
  my @conditions = do for $<condition> Z $<multi-template> -> ($cond, $block) {
    $cond.made => $block.made
  }
  my $else = $<else-block>.made;

  make StaticTemplate::AST::If.new:
    :@conditions,
    |(:$else with $else),
}

method code:sym<set>($/) {
  my $name = $<var-name>.Str;
  my $initial-value = $<initial-value>.made;
  make StaticTemplate::AST::VariableDeclaration.new: :$name, :$initial-value
}

method code:sym<set-eq>($/) {
  self."code:sym<set>"($/)
}

method code:sym<raw>($/) {
  make StaticTemplate::AST::Text.new :text($<text>.Str)
}

method code:sym<macro>($/) {
  my $name = $<macro-name>.Str;
  my $initial-value = $<block>.made;
  my $signature = $<signature>.made;
  my $type = StaticTemplate::WantedType.new: :name<macro>, :$signature;
  make StaticTemplate::AST::VariableDeclaration.new: :$name, :$initial-value, :$type
}

method param:sym<positional>($/) {
  my $var-name     = $<var-name>.Str;
  my $default      = $<default>.made;
  my $wanted-types = $<wanted-types>.made;
  make StaticTemplate::AST::Param.new: :!named, :$var-name, :$default, |(:$wanted-types with $wanted-types), :optional($<optional>.Str ne "!")
}
method param:sym<named>($/) {
  my $var-name     = $<var-name>.Str;
  my $arg-name     = $<arg-name>.Str;
  my $default      = $<default>.made;
  my $wanted-types = $<wanted-types>.made;
  make StaticTemplate::AST::Param.new: :named, :$arg-name, :$var-name, :$default, :$wanted-types, :optional($<optional>.Str ne "!")
}
method param:sym<homonamed>($/) {
  my $var-name     = $<var-name>.Str;
  my $default      = $<default>.made;
  my $wanted-types = $<wanted-types>.made;
  make StaticTemplate::AST::Param.new: :named, :$var-name, :$default, :$wanted-types, :optional($<optional>.Str ne "!")
}

method signature($/) {
  my (:@named, :@positional) := $<param>.map(*.made).classify: { .named ?? "named" !! "positional" };
  make StaticTemplate::Signature.new: :@named, :@positional
}

method number($/) { make StaticTemplate::AST::Statement.new: :data($/.Numeric) }
method value:sym<number>($/) { make $<number>.made }
method value:sym<dstr>($/) { make StaticTemplate::AST::Statement.new: :data($<str>.Str) }
method value:sym<sstr>($/) { make StaticTemplate::AST::Statement.new: :data($<str>.Str) } # TODO: review
method value:sym<operation>($/) { make $<term-op1>.made }
method value:sym<comparation>($/) { make self.op: $<term-op1>».made, $<cmp-op>».Str }
method value:sym<true>($/) { make StaticTemplate::AST::Statement.new: :data(True) }
method value:sym<false>($/) { make StaticTemplate::AST::Statement.new: :data(False) }

method factor($/)   { make ($<number> // $<variable>).made }
method term-op2($/) {
  make self.op: $<factor>».made, $<op2>».Str
}
method term-op1($/) {
  make self.op: $<term-op2>».made, $<op1>».Str
}

multi method op(@n [$left, *@nums], @o [$op, *@ops]) {
  StaticTemplate::AST::Operation.new: :$left, :$op, :right(self.op: @nums, @ops)
}

multi method op([$num], []) {
  $num
}

#rule code:sym<test> {
#  [<.start-block> ~ <.end-block> \w+] ~ [<.start-block> ~ <.end-block> \w+] \w*
#}
#
#
#token start-block { '{%' }
#token start-val   { '{{' }
#token end-block   { '%}' }
#token end-val     { '}}' }
#
#proto token start-code {*}
#token start-code:sym<block> { <.start-block> }
#token start-code:sym<val> { <.start-val> }
#
#proto token end-code {*}
#token end-code:sym<block> { <.end-block> }
#token end-code:sym<val> { <.end-val> }
#
