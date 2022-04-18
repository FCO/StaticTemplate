use StaticTemplate::Signature;

unit class StaticTemplate::Type;

has ::?CLASS                  $.parent = ::?CLASS.type: "any";
has ::?CLASS                  $.of;
has Str()                     $.name;
has Bool                      $.function = False;
has StaticTemplate::Signature $.signature;
has                           @.enum;

multi method type(::?CLASS:U: "any") {
  $ //= ::?CLASS.new: :name<any>, :parent(Nil)
}

multi method type(::?CLASS:U: "string") {
  $ //= ::?CLASS.new: :name<string>;
}

multi method type(::?CLASS:U: "number") {
  $ //= ::?CLASS.new: :name<number>;
}

multi method type(::?CLASS:U: "boolean") {
  $ //= ::?CLASS.new: :name<boolean>;
}

multi method type(::?CLASS:U: "array") {
  $ //= ::?CLASS.new: :name<array>;
}

multi method type(::?CLASS:U: "object") {
  $ //= ::?CLASS.new: :name<object>;
}

multi method new(Str $name where /^ "enum(" ~ ")" [$<word>=<[\w\s]>+]+ %% [<.ws> "," <.ws>]/) {
  ::?CLASS.new: :$name, :parent(::?CLASS.type: "string"), :enum($<word>».Str)
}

multi method new(Str $name) {
  if $name ∈ <any string number boolean> {
    return ::?CLASS.type: $name
  }
  do if $name ~~ /^ $<name>=\w+ [ "[" ~ "]" $<of>=.*? ] $/ {
    ::?CLASS.new: :$<name>, :of(::?CLASS.new: ~$<of>)
  } elsif $name ~~ /^\w+$/ {
    ::?CLASS.new: :$name
  } else {
    die "Error creating type '$name'"
  }
}

submethod TWEAK(:$name, :$of, |) {
  if $name eq ("array"|"object") && not $of.defined {
    $!of = ::?CLASS.type: "any"
  }
}

method mro {
  gather { self!take-mro }
}

method !take-mro {
  take self;
  $_!take-mro with $.parent
}

multi method isa(Str $other) {
  nextwith ::?CLASS.new: $other
}

multi method isa(::?CLASS $other) {
  $other ∈ $.mro
}

method name {
  return "enum({ @!enum.join: ", " })" if @!enum;
  "{ $!name }{ "[{ .name }]" with $!of }"
}
