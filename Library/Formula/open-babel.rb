require 'formula'

class OasaPythonModule < Requirement
  def message; <<-EOS.undent
    The oasa Python module is required for some operations.
    It can be downloaded from:
      http://bkchem.zirael.org/oasa_en.html
    Or with the command:
      pip install -f http://bkchem.zirael.org/ oasa==0.13.1
    EOS
  end
  def satisfied?
    args = %W{/usr/bin/env python -c import\ oasa}
    quiet_system *args
  end
end

def which_python
  "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
end

def site_package_dir
  "#{lib}/#{which_python}/site-packages"
end

class OpenBabel < Formula
  homepage 'http://openbabel.org/'
  url 'http://sourceforge.net/projects/openbabel/files/openbabel/2.2.3/openbabel-2.2.3.tar.gz'
  md5 '7ea8845c54d6d3a9be378c78088af804'
  head 'https://openbabel.svn.sourceforge.net/svnroot/openbabel/openbabel/trunk'

  depends_on OasaPythonModule.new

 if ARGV.build_head? ##### FOR BUILDING THE HEAD ONLY #####
  depends_on 'cmake' => :build
  depends_on 'swig' => :build
  depends_on 'eigen'

  def install
    ENV.deparallelize
    args = std_cmake_parameters.split
    args << "-DEIGEN3_INCLUDE_DIR='#{HOMEBREW_PREFIX}/include/eigen3'"
    args << '-DPYTHON_BINDINGS=ON'
    args << '-DRUN_SWIG=TRUE' if ARGV.build_head?

    # This block is copied from opencv.rb formula:
    #
    #  The CMake `FindPythonLibs` Module is dumber than a bag of hammers when
    #  more than one python installation is available---for example, it clings
    #  to the Header folder of the system Python Framework like a drowning
    #  sailor.
    #
    #  This code was cribbed from the VTK formula and uses the output to
    #  `python-config` to do the job FindPythonLibs should be doing in the first
    #  place.
    python_prefix = `python-config --prefix`.strip
    # Python is actually a library. The libpythonX.Y.dylib points to this lib, too.
    if File.exist? "#{python_prefix}/Python"
      # Python was compiled with --framework:
      args << "-DPYTHON_LIBRARY='#{python_prefix}/Python'"
      args << "-DPYTHON_INCLUDE_DIR='#{python_prefix}/Headers'"
    else
      python_lib = "#{python_prefix}/lib/lib#{which_python}"
      if File.exists? "#{python_lib}.a"
        args << "-DPYTHON_LIBRARY='#{python_lib}.a'"
      else
        args << "-DPYTHON_LIBRARY='#{python_lib}.dylib'"
      end
      args << "-DPYTHON_INCLUDE_DIR='#{python_prefix}/include/#{which_python}'"
    end

    args << '.'
    system "cmake", *args
    system "make"
    system "make install"

    # move python stuff into #{site_package_dir}
    mkdir_p site_package_dir
    mv ["#{lib}/_openbabel.so", "#{lib}/openbabel.py", "#{lib}/pybel.py"], site_package_dir
    # remove the spurious cmake and pkgconfig folders from lib
    rmtree "#{lib}/cmake"
    rmtree "#{lib}/pkgconfig"

  end

  def caveats; <<-EOS.undent
    The Python bindings were installed to #{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages
    so you may need to update your PYTHONPATH like so:
      export PYTHONPATH="#{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages:$PYTHONPATH"
    To make this permanent, put it in your shell's profile (e.g. ~/.profile).

    To draw images from python, you will need to get the oasa Python module:
      pip install -f http://bkchem.zirael.org/ oasa==0.13.1
    EOS
  end

 else ##### ONLY FOR BUILDING 2.2.3 #####

  def options
    [
      ["--perl", "Perl bindings"],
      ["--python", "Python bindings"],
      ["--ruby", "Ruby bindings"]
    ]
  end

  def install
    args = ["--disable-dependency-tracking",
            "--prefix=#{prefix}"]
    args << '--enable-maintainer-mode' if ARGV.build_head?

    system "./configure", *args
    system "make"
    system "make install"

    ENV['OPENBABEL_INSTALL'] = prefix

    # Install the python bindings
    if ARGV.include? '--python'
      cd 'scripts/python' do
        system "python", "setup.py", "build"
        system "python", "setup.py", "install", "--prefix=#{prefix}"
      end
    end

    # Install the perl bindings.
    if ARGV.include? '--perl'
      cd 'scripts/perl' do
        # because it's not yet been linked, the perl script won't find the newly
        # compiled library unless we pass it in as LD_LIBRARY_PATH.
        ENV['LD_LIBRARY_PATH'] = "lib"
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
      cd 'scripts/ruby' do
        system "ruby", "extconf.rb",
               "--with-openbabel-include=#{include}",
               "--with-openbabel-lib=#{lib}"

        # Don't build i386 version when libopenbabel can't link to it.
        inreplace "Makefile", '-arch i386 ', ''

        # With the following line it puts things in #{prefix} (where ruby can't find them).
        # Without, it puts them in /Library/Ruby/...
        #ENV['DESTDIR']=prefix
        system "make"
        system "make install"
      end
    end
  end

  def caveats; <<-EOS.undent
    This is version 2.2.3 of Open Babel, which is a bit old.
    You may want to install with --HEAD to get the latest developer version.
    (The most recent official release, 2.3.1, is not available through homebrew).
    EOS
  end
 end
end
