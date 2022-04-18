use StaticTemplate::Grammar;
use StaticTemplate::Type;

unit class StaticTemplate::WantedType;

has Str $.name;
has @.options; # where *.all ~~ ::?CLASS | StaticTemplate::Type;

method options {
  my @sub = do for @!options -> $opt {
    do if $opt ~~ ::?CLASS {
      |$opt.options
    } else {
      $opt
    }
  }
  do with $!name {
    StaticTemplate::Type.new: :$!name, :of($_) for @sub
  } else {
    @sub
  }
}

multi method new(Str $name) {
  do if StaticTemplate::Grammar.parse: $name, :rule<list-of-wanted-types> -> $/ {
    do if @<wanted-type> == 1 {
      my $type = @<wanted-type>.first<base>.Str;
      do if @<wanted-type>.first<sub-types> -> $_ {
        do if @$_ > 1 {
          ::?CLASS.new: :name($type), :options(.<wanted-type>.map: { ::?CLASS.new: .Str })
        } else {
          my $of = ::?CLASS.new: .Str;
          if $of ~~ StaticTemplate::Type {
            StaticTemplate::Type.new: :name($type), :$of
          } else {
            ::?CLASS.new: :name($type), :options[$of]
          }
        }
      } else {
        StaticTemplate::Type.new: $/.Str
      }
    } else {
      my @options = @<wanted-type>.map: { ::?CLASS.new: .Str }
      ::?CLASS.new: :@options
    }
  }
}

method name {
  my $name = $!name ?? $!name !! "";
  my $opts = @!options ?? @!options.map(*.name).join: "|" !! "";
  "{ $name }{ "[" if $name && $opts }{ $opts }{ "]" if $name && $opts }"
}
