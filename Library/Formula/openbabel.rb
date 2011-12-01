require 'formula'
# Use the head (i.e. do 'brew upgrade openbabel --HEAD')


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
    args << "-DEIGEN3_INCLUDE_DIR='#{HOMEBREW_PREFIX}/include/eigen3'"
    
    Dir.mkdir 'build'
    Dir.chdir 'build' do
      system 'cmake', '..', *args
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
