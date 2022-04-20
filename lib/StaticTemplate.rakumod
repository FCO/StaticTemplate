use StaticTemplate::RequirementService;
use X::StaticTemplate::CompileError;
unit class StaticTemplate;

method eval(Str $code) {
  CATCH {
    $.catch-error($_)
  }
  await StaticTemplate::RequirementService.instance.eval: $code
}

method render-dir(IO() $dir, :$cwd = $dir, :$extension = "njk", IO() :$output-dir) {
  my $out-dir;
  if $output-dir {
    $out-dir = $output-dir.add: $dir.relative: $cwd.IO;
    $output-dir.mkdir unless $output-dir.e;
    .mkdir unless .e given $out-dir;
  }
  race for $dir.dir -> $file {
    if $file.d {
      self.render-dir: $file, :$extension, :$cwd, |(:$output-dir with $output-dir);
      next
    }
    next unless $file.extension eq $extension;
    my &output = do if $output-dir {
      -> $_ {
        $out-dir.add($file.basename).spurt: $_
      }
    } else { &say }

    StaticTemplate::RequirementService.instance.get($file.path).then({
      CATCH {
        when X::StaticTemplate::CompileError {
          note "\o033[31;1mERROR\o033[m on file '\o033[1m{ $file.path }\o033[m':";
          note .message;
          if $*FATAL {
            note "Using \o033[1m--fatal\o033[m exiting...";
            exit(1)
          }
          note "\o033[1mCompiling other files...\o033[m";
        }
      }
      output .result.run
    })
  }
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
