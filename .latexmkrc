# latexmk configuration shared by `make`, VS Code (LaTeX Workshop) and CI.
# The repository root is found by walking up from the current directory
# until format/lnotes.cls is seen, so this works from any cwd
# (repo root, en/, ja/, en/lessons/ ...).  latexmk evals this file, so
# __FILE__ cannot be used to locate it.
use Cwd qw(getcwd);
use File::Basename;
my $root = getcwd();
until (-e "$root/format/lnotes.cls") {
    my $up = dirname($root);
    die ".latexmkrc: cannot find repository root (format/lnotes.cls) above " . getcwd() . "\n" if $up eq $root;
    $root = $up;
}

# Our directories go *first* so format/lnotes.cls always wins over anything
# with the same name in the TeX distribution.  The trailing ':' keeps the
# distribution's default search path.
$ENV{TEXINPUTS}  = "$root/format//:$root:" . ($ENV{TEXINPUTS}  // '');
$ENV{BIBINPUTS}  = "$root:"                . ($ENV{BIBINPUTS}  // '');
$ENV{INDEXSTYLE} = "$root/format:"         . ($ENV{INDEXSTYLE} // '');

$pdf_mode  = 4;                       # 4 = lualatex
$lualatex  = 'lualatex -interaction=nonstopmode -file-line-error -synctex=1 %O %S';
$out_dir   = 'build';
$biber     = 'biber %O %S';
# upmendex handles both English and Japanese.  The style file (headings,
# symbol group names) and the -g flag (gojuon headings) depend on the
# edition, which is inferred from the directory being built (en/ or ja/).
$makeindex = 'internal ln_upmendex %O -o %D %S';
sub ln_upmendex {
    # A chapter without index entries yields an empty .idx, which upmendex
    # rejects; write an empty .ind instead so chapter-only builds succeed.
    my ($idx, $ind) = ($_[-1], undef);
    for my $i (0 .. $#_ - 1) { $ind = $_[$i + 1] if $_[$i] eq '-o'; }
    if (-z $idx && defined $ind) {
        open(my $fh, '>', $ind) or return 1;
        print $fh "\\begin{theindex}\n\\end{theindex}\n";
        close $fh;
        return 0;
    }
    my $lang = (Cwd::getcwd() =~ m{/ja(/|$)}) ? 'ja' : 'en';
    my @opts = ('-s', "$root/format/lnotes-$lang.ist");  # absolute: no kpathsea lookup
    push @opts, '-g' if $lang eq 'ja';
    return system('upmendex', @opts, @_);
}
$max_repeat = 6;
$clean_ext = 'synctex.gz run.xml bcf ist idx ind ilg';
