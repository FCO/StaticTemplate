use StaticTemplate::Parser;

unit class StaticTemplate::RequirementService;

has StaticTemplate::Parser $.parser handles <parse-file> .= new;
has Lock                   $!lock                        .= new;
has                        %!requires;
has                        %!required-by;

method new { !!! }

method instance(::?CLASS:U:) { $ = self.bless }

method get($file, :$from) {
  %!required-by.push: $file => $from;
  self!get: $file
}

method reload($file) {
  self!get: $file
}

method !get($file, Bool :$reload) {
  if $reload or %!requires{ $file }:exists {
    $!lock.protect: { %!requires{ $file } = start $.parse-file: $file }
  }
  %!requires{ $file }
}
