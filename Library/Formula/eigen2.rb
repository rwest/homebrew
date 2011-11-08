require 'formula'

class Eigen2 < Formula
  url 'http://bitbucket.org/eigen/eigen/get/2.0.16.tar.gz'
  homepage 'http://eigen.tuxfamily.org/'
  md5 'e6228de636638059299bcc229b71f3ff'

  # The old version of Eigen 2
  # based on https://github.com/mxcl/homebrew/blob/0476235ce0724f8ce6729c7962184207342fe938/Library/Formula/eigen.rb
  depends_on 'cmake' => :build

  def install
    system "cmake . #{std_cmake_parameters}"
    system "make install"
  end
end
