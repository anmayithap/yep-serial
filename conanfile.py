from conan import ConanFile
from conan.tools.cmake import cmake_layout


class ConanRecipe(ConanFile):

    settings = "os", "compiler", "build_type", "arch",
    generators = "CMakeToolchain", "CMakeDeps",

    def requirements(self):
        self.requires("boost/[~1.84]")
        self.requires("catch2/3.5.2")
        self.requires("fmt/10.2.1")
        self.requires("spdlog/1.13.0")
        self.requires("pybind11/2.11.1")

    def layout(self):
        cmake_layout(self)
