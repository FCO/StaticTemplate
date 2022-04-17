use StaticTemplate::Signature;

unit class StaticTemplate::Type;

has ::?CLASS                  $.parent = ::?CLASS.type: "any";
has Str                       $.name;
has Bool                      $.function = False;
has StaticTemplate::Signature $.signature;

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

method mro {
  gather { self!take-mro }
}

method !take-mro {
  take self;
  $_!take-mro with $.parent
}

method isa(::?CLASS $other) {
  $other ∈ $.mro
}
