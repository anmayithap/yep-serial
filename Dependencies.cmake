# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(yep_serial_setup_dependencies)

  # For each dependency, see if it's
  # already been provided to us by a parent project
  find_package(Catch2 "3.5" CONFIG REQUIRED)
  
  if(NOT TARGET boost::boost)
    find_package(Boost "1.84" CONFIG REQUIRED)
  endif()

  if(NOT TARGET fmtlib::fmtlib)
    find_package(fmt "10.2.1" CONFIG REQUIRED)
  endif()

  if(NOT TARGET spdlog::spdlog)
    find_package(spdlog "1.13" CONFIG REQUIRED)
  endif()

  if(NOT TARGET pybind11::pybind11_all_do_not_use)
    find_package(pybind11 "2.11" CONFIG REQUIRED)
  endif()

endfunction()