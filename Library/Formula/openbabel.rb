require 'formula'
# Use the head (i.e. do 'brew upgrade openbabel --HEAD')


def which_python
  "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
end
def site_package_dir
  "#{lib}/#{which_python}/site-packages"
end

class Openbabel < Formula
  url 'http://sourceforge.net/projects/openbabel/files/openbabel/2.3.1/openbabel-2.3.1.tar.gz'
  homepage 'http://openbabel.org'
  md5 '1f029b0add12a3b55582dc2c832b04f8'
  head 'https://openbabel.svn.sourceforge.net/svnroot/openbabel/openbabel/trunk'

  depends_on 'cmake' => :build
  depends_on 'swig' => :build
  depends_on 'eigen'
 # depends_on 'zlib'
  depends_on 'libxml2' # required for CML
  
  # OASA doesn't have a brew formula yet, but it's at 
  # http://bkchem.zirael.org/oasa_en.html
  #depends_on 'oasa' => :optional

  def install
  #  system "./configure", # "--disable-debug", "--disable-dependency-tracking",
  #                        "--prefix=#{prefix}", "--enable-maintainer-mode"

    args = std_cmake_parameters.split
    args << "-DRUN_SWIG=TRUE"
    args << "-DPYTHON_BINDINGS=ON"
    args << "-DPYTHON_PREFIX='#{prefix}'"
    args << "-DEIGEN3_INCLUDE_DIR='#{HOMEBREW_PREFIX}/include/eigen3'"
    

    ## This code was copied from the opencv formula:
    # The CMake `FindPythonLibs` Module is dumber than a bag of hammers when
    # more than one python installation is available---for example, it clings
    # to the Header folder of the system Python Framework like a drowning
    # sailor.
    # This code was cribbed from the VTK formula and uses the output to
    # `python-config` to do the job FindPythonLibs should be doing in the first
    # place.
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
    args << "-DPYTHON_PACKAGES_PATH='#{lib}/#{which_python}/site-packages'"


    Dir.mkdir 'build'
    Dir.chdir 'build' do
      system 'cmake', '..', *args
      system 'grep -i python CMakeCache.txt'
      system 'make install'
    end
    
  end

  def test
    # This test will fail and we won't accept that! It's enough to just
    # replace "false" with the main program this formula installs, but
    # it'd be nice if you were more thorough. Test the test with
    # `brew test openbabel`. Remove this comment before submitting
    # your pull request!
    Dir.chdir 'build' do
      system "make test"
    end
  end
end
