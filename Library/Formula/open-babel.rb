require 'formula'

class OpenBabel <Formula
  url 'http://sourceforge.net/projects/openbabel/files/openbabel/2.2.3/openbabel-2.2.3.tar.gz/download'
  head 'https://openbabel.svn.sourceforge.net/svnroot/openbabel/openbabel/trunk'
  homepage 'http://openbabel.org/'
  md5 '7ea8845c54d6d3a9be378c78088af804'
  version '2.2.3'

  depends_on 'libxml2' # required for CML
  # OASA doesn't have a brew formula yet, but it's at 
  # http://bkchem.zirael.org/oasa_en.html
  #depends_on 'oasa' => :optional

  def options
    [
      ["--ruby", "Ruby bindings"],
      ["--python", "Python bindings"],
      ["--perl", "Perl bindings"]
    ]
  end
  
  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          (ARGV.build_head? ? '--enable-maintainer-mode' : '')
    system "make"
    system "make install"

    ENV['OPENBABEL_INSTALL']=prefix

    # Install the python bindings
    if ARGV.include? '--python'
      Dir.chdir 'scripts/python' do
        system "python", "setup.py", "build"
        system "python", "setup.py", "install", "--prefix=#{prefix}"
      end
    end


    # Install the perl bindings.
    if ARGV.include? '--perl'
      Dir.chdir 'scripts/perl' do
        # because it's not yet been linked, the perl script won't find the newly 
        # compiled library unless we pass it in as LD_LIBRARY_PATH.
        ENV['LD_LIBRARY_PATH']="#{lib}"
        system 'perl', 'Makefile.PL'
        # With the additional argument "PREFIX=#{prefix}" it puts things in #{prefix} (where perl can't find them).
        # Without, it puts them in /Library/Perl/...
        inreplace "Makefile" do |s|
          # Fix the broken Makefile (-bundle not allowed with -dynamiclib).
          # I think this is a SWIG error, but I'm not sure.
          s.gsub! '-bundle ', ''
          # Don't waste time building PPC version.
          s.gsub! '-arch ppc ', ''
          # Don't build i386 version when libopenbabel can't link to it.
          s.gsub! '-arch i386 ', ''
        end
        system "make"
        system "make test"
        system "make install"
      end
    end

    # Install the ruby bindings.
    if ARGV.include? '--ruby'
      Dir.chdir 'scripts/ruby' do
        system "ruby", "extconf.rb",
               "--with-openbabel-include=#{include}",
               "--with-openbabel-lib=#{lib}"
        inreplace "Makefile" do |s|
          # Don't build i386 version when libopenbabel can't link to it.
          s.gsub! '-arch i386 ', ''
        end
        # With the following line it puts things in #{prefix} (where ruby can't find them).
        # Without, it puts them in /Library/Ruby/...
        #ENV['DESTDIR']=prefix 
        system "make"
        system "make install"
      end
    end
  end

  def caveats; <<-EOS.undent
    To build ruby, python or perl bindings use --ruby --python or --perl options.
    EOS
  end

end
