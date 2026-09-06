#!/usr/bin/env perl
use v5.36;    ## no critic (ValuesAndExpressions::ProhibitVersionStrings)
use Getopt::Long   qw(GetOptions);
use File::Basename qw(dirname);
use Cwd            qw(abs_path);

# Helper function to read entire file as UTF-8
sub readFile ($filePath) {
    open my $fh, '<:encoding(UTF-8)', $filePath
      or die "Cannot open '$filePath' for reading: $!\n";
    local $/ = undef;
    my $content = <$fh>;
    close $fh;
    return $content;
}

# Helper function to write entire file as UTF-8
sub writeFile ( $filePath, $content ) {
    open my $fh, '>:encoding(UTF-8)', $filePath
      or die "Cannot open '$filePath' for writing: $!\n";
    print {$fh} $content;
    close $fh;
    return 1;
}

# Compute rolling tags for semantic s6-overlay releases
sub computeExtraTags ($version) {
    my @parts = split qr/[.]/msx, $version;
    return ( ( @parts >= 2 ? ("$parts[0].$parts[1]") : () ),
        ( @parts >= 3 ? ("$parts[0].$parts[1].$parts[2]") : () ), 'latest', );
}

# Update Dockerfile default ARG
sub updateDockerfileContent ( $content, $newVersion ) {
    my $regexArg = qr/^ARG\s+S6_OVERLAY_VERSION="[^"]*"/msx;
    die "Failed to find ARG S6_OVERLAY_VERSION in Dockerfile\n"
      unless $content =~ /$regexArg/msx;

    my $updatedContent = $content =~ s/$regexArg/ARG S6_OVERLAY_VERSION="$newVersion"/rmsx;
    return $updatedContent;
}

# Update hack/docker-bake.hcl matrix and latest version
sub updateDockerBakeContent ( $content, $currentLatest, $newVersion ) {
    my $quotedPrev = quotemeta($currentLatest);
    my $regexPrev  = qr/(^\s*"$quotedPrev"\s*=\s*\{[^}]*extra_tags\s*=\s*)\[[^\]]*\]/msx;
    die "Could not find extra_tags entry for current latest '$currentLatest' in docker-bake.hcl\n"
      unless $content =~ /$regexPrev/msx;

    my $clearedContent = $content =~ s/$regexPrev/${1}[]/rmsx;

    my @tags         = computeExtraTags($newVersion);
    my $tagsStr      = join( ', ', map { qq{"$_"} } @tags );
    my $newEntryLine = qq{    "$newVersion"   = { extra_tags = [$tagsStr] }};

    my $quotedNew  = quotemeta($newVersion);
    my $regexNew   = qr/^\s*"$quotedNew"\s*=/msx;
    my $regexExist = qr/(^\s*"$quotedNew"\s*=\s*\{[^}]*extra_tags\s*=\s*)\[[^\]]*\]/msx;

    my $matrixUpdatedContent;
    if ( $clearedContent =~ /$regexNew/msx ) {
        $matrixUpdatedContent = $clearedContent =~ s/$regexExist/${1}[$tagsStr]/rmsx;
    } else {
        my $headPattern   = qr/variable \s+ "S6_VERSIONS" \s+ \{ \s+ default \s+ = \s+ \{/msx;
        my $tailPattern   = qr/\n \s* \} \s* \n \}/msx;
        my $regexVersions = qr/($headPattern .*?) ($tailPattern)/msx;
        if ( $clearedContent =~ /$regexVersions/msx ) {
            my ( $body, $closing ) = ( $1, $2 );
            my $trimmedBody = $body =~ s/\s+$//rmsx;
            $matrixUpdatedContent =
              $clearedContent =~ s/\Q$body$closing\E/$trimmedBody\n$newEntryLine$closing/rmsx;
        } else {
            die "Could not locate S6_VERSIONS map in docker-bake.hcl\n";
        }
    }

    my $regexLatest = qr/(variable\s+"LATEST_VERSION"\s+\{\s+default\s+=\s+")[^"]+(")/msx;
    die "Could not find variable \"LATEST_VERSION\" in docker-bake.hcl\n"
      unless $matrixUpdatedContent =~ /$regexLatest/msx;

    my $finalContent = $matrixUpdatedContent =~ s/$regexLatest/${1}$newVersion${2}/rmsx;

    return $finalContent;
}

# Update README.md version occurrences
sub updateReadmeContent ( $content, $currentLatest, $newVersion ) {
    my $quotedPrev  = quotemeta($currentLatest);
    my $regexReadme = qr/$quotedPrev/msx;
    die "Could not find current latest version '$currentLatest' in README.md\n"
      unless $content =~ /$regexReadme/msx;

    my $updatedContent = $content =~ s/$regexReadme/$newVersion/grmsx;
    return $updatedContent;
}

sub run () {
    my $isDryRun = 0;
    my $repoRoot = abs_path( dirname(__FILE__) . '/..' );

    GetOptions(
        'repo-root=s' => \$repoRoot,
        'dry-run'     => \$isDryRun,
    ) or die "Usage: $0 [--dry-run] [--repo-root DIR] <new_version>\n";

    my $version = shift @ARGV
      or die
"Error: Missing new version argument.\nUsage: $0 [--dry-run] [--repo-root DIR] <new_version>\n";

    my $regexLeadingV = qr/^v/msx;
    my $cleanVersion  = $version =~ s/$regexLeadingV//rmsx;

    my $regexSemver = qr/^\d+(?:\.\d+)+$/msx;
    die
"Error: Invalid version format '$cleanVersion'. Expected semantic version numbers (e.g. 3.2.0.3)\n"
      unless $cleanVersion =~ /$regexSemver/msx;

    my $dockerfilePath = "$repoRoot/Dockerfile";
    my $bakePath       = "$repoRoot/hack/docker-bake.hcl";
    my $readmePath     = "$repoRoot/README.md";

    die "File not found: $dockerfilePath\n" unless -f $dockerfilePath;
    die "File not found: $bakePath\n"       unless -f $bakePath;
    die "File not found: $readmePath\n"     unless -f $readmePath;

    my $bakeContent     = readFile($bakePath);
    my $regexFindLatest = qr/variable\s+"LATEST_VERSION"\s+\{\s+default\s+=\s+"([^"]+)"/msx;
    my ($currentLatest) = ( $bakeContent =~ /$regexFindLatest/msx );
    die "Could not find variable \"LATEST_VERSION\" in $bakePath\n" unless defined $currentLatest;

    say "Current latest version: $currentLatest";
    say "Target new version:     $cleanVersion";

    if ( $currentLatest eq $cleanVersion ) {
        say "Version $cleanVersion is already the latest version. Nothing to update.";
        return 0;
    }

    my $dockerfileContent = readFile($dockerfilePath);
    my $newDockerfile     = updateDockerfileContent( $dockerfileContent, $cleanVersion );
    my $newBake           = updateDockerBakeContent( $bakeContent, $currentLatest, $cleanVersion );

    my $readmeContent = readFile($readmePath);
    my $newReadme     = updateReadmeContent( $readmeContent, $currentLatest, $cleanVersion );

    if ($isDryRun) {
        say '[DRY-RUN] Files validated and updated in memory successfully.';
        return 0;
    }

    writeFile( $dockerfilePath, $newDockerfile );
    writeFile( $bakePath,       $newBake );
    writeFile( $readmePath,     $newReadme );

    say
"Successfully updated Dockerfile, hack/docker-bake.hcl, and README.md for version $cleanVersion.";
    return 0;
}

exit run();
