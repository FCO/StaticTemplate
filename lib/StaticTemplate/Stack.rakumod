unit class StaticTemplate::Stack;

class Var {
  has Str  $.name is required;
  has Str  $.type = "any";
  has UInt $.line;
  has      $.initial-value;
}

has Var      %.vars;
has ::?CLASS $.parent;

method new-scope {
  ::?CLASS.new: :parent(self)
}

method define($name, :$type, UInt :$line, :$initial-value) {
  die "Variable $name first defined at line" with %!vars{$name};

  %!vars{$name} = Var.new: :$name, |(:$type with $type), :$line
}

method get($name) {
  .return with %!vars{$name};

  .get($name) with $!parent
}

method scope-variables {
  %!vars.keys
}

method all-variables {
  [|self.scope-variables, |(|.all-variables with $!parent)].unique
}
