use StaticTemplate::Parser;

unit class StaticTemplate::RequirementService;

has StaticTemplate::Parser $.parser handles <parse-file> .= new;
has Lock                   $!lock                        .= new;
has                        %!requires;

method new { !!! }

method instance(::?CLASS:U:) { $ //= self.bless }

method eval-to-ast(Str $code) {
  start $!parser.parse: $code
}

method eval(Str $code) {
  $.eval-to-ast($code).then: *.result.run
}

method get($file, :$from) {
  %!requires.push: $file => $from;
  self!get: $file
}

method reload($file) {
  self!get: $file, :reload;
  for %!requires{ $file } -> $required {
    self!get: $required; :reload
  }
}

method !get($file, Bool :$reload) {
  if $reload or %!requires{ $file }:exists {
    $!lock.protect: { %!requires{ $file } = start $!parser.parse-file: $file }
  }
  %!requires{ $file }
}
