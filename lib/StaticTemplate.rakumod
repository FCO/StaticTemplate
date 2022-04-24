use StaticTemplate::RequirementService;
use X::StaticTemplate::CompileError;
unit class StaticTemplate;

has Bool $.watch;
has Supplier $!in-supplier .= new;
has Supply   $!in-supply    = $!in-supplier.Supply;
has Supplier $!out-supplier .= new;
has Supply   $!out-supply    = $!out-supplier.Supply;
has          %!watching;
has Promise  $!watching;

multi rm(IO $  where !.e) {}
multi rm(IO $_ where .d) { race for .dir { .&rm }; .rmdir }
multi rm(IO $_ where .f) { .unlink }

method TWEAK(|) {
  $!watching = start self!await
}

method !await {
  react {
    whenever $!in-supply -> ( IO() :$read, IO() :$write, Bool :$exists ) {
      #say [ :$read, :$write, :$exists ];
      say "Processing file \o033[1m$read.relative()\o033[m";
      rm $write;
      self.render-file: $read, :output(self.output: $write);
    }
    whenever $!out-supply -> ( IO() :$read, IO() :$write, Bool :$exists ) {
      say [ :$read, :$write, :$exists ];
    }
  }
}

method eval(Str $code) {
  CATCH {
    $.catch-error($_)
  }
  await StaticTemplate::RequirementService.instance.eval: $code
}

method render-file(IO() $file, :&output = &say) {
  StaticTemplate::RequirementService.instance.get($file.resolve.path).then({
    CATCH {
      when X::StaticTemplate::CompileError {
        note "\o033[31;1mERROR\o033[m on file '\o033[1m{ $file.path }\o033[m':";
        note .message;
        if $*FATAL {
          note "Using \o033[1m--fatal\o033[m exiting...";
          exit(1)
        }
        note "\o033[1mcontinuing...\o033[m";
      }
    }
    output .result.run
  })
}

method output($write) {
  do if $write {
    -> $_ {
      $write.spurt: $_
    }
  } else {
    &say
  }
}

method render-dir(IO() $dir, :$cwd = $dir, :$extension = "njk", IO() :$output-dir) {
  rm $output-dir if $dir === $cwd;
  my $out-dir;
  if $output-dir {
    $out-dir = $output-dir.add: $dir.relative: $cwd.IO;
    $output-dir.mkdir unless $output-dir.e;
    .mkdir unless .e given $out-dir;
  }
  self.watch: $dir, :$cwd, :$output-dir if $!watch;
  my @proms = race for $dir.dir -> $file {
    if $file.d {
      self.render-dir: $file, :$extension, :$cwd, |(:$output-dir with $output-dir), :$!watch;
      next
    }
    next unless $file.extension eq $extension;

    my $write = $out-dir.add: $file.basename;
    #self.render-file: $file, :output(self.output: $write);
    $!in-supplier.emit: { :read($file), :$write, :exists($file.e) }
  }
  .return with $!watching;
  @proms
}

method watch(IO() $dir, IO() :$cwd, IO() :$output-dir) {
  self!watch-in:  $dir, :$cwd, :$output-dir;
  self!watch-out: $dir, :$cwd, :$output-dir;
}

method !watch-in(IO() $dir, IO() :$cwd!, IO() :$output-dir!) {
  %!watching{$dir} = $dir.watch.tap: -> (IO() :path($read), |) {
    my IO() $write = $output-dir.add: $read.relative: $cwd;
    $!in-supplier.emit: { :$read, :$write, :exists($read.e) }
    if $read.d {
      if $read.e {
        self!watch-in: $read, :$cwd, :$output-dir;
      } else {
        %!watching{$read}:delete
      }
    }
  }
}

method !watch-out(IO() $dir, IO() :$cwd!, IO() :$output-dir!) {
  #%!watching{$output-dir} = $output-dir.watch.tap: -> (IO() :path($write), |) {
  #  my IO() $read = $dir.add: $write.relative: $cwd;
  #  unless $read.e {
  #    say "out";
  #    $!out-supplier.emit: { :$read, :$write, :!exists }
  #  }
  #}
}

method catch-error($_) {
  when X::StaticTemplate::CompileError {
    note .message;
    exit 1
  }
}

=begin pod

=head1 NAME

StaticTemplate - blah blah blah

=head1 SYNOPSIS

=begin code :lang<raku>

use StaticTemplate;

=end code

=head1 DESCRIPTION

StaticTemplate is ...

=head1 AUTHOR

 <foliveira@gocardless.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2022 

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
