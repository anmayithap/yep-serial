include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(yep_serial_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(yep_serial_setup_options)
  option(yep_serial_ENABLE_HARDENING "Enable hardening" ON)
  option(yep_serial_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    yep_serial_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    yep_serial_ENABLE_HARDENING
    OFF)

  yep_serial_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR yep_serial_PACKAGING_MAINTAINER_MODE)
    option(yep_serial_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(yep_serial_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(yep_serial_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(yep_serial_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(yep_serial_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(yep_serial_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(yep_serial_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(yep_serial_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(yep_serial_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(yep_serial_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(yep_serial_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(yep_serial_ENABLE_PCH "Enable precompiled headers" OFF)
    option(yep_serial_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(yep_serial_ENABLE_IPO "Enable IPO/LTO" ON)
    option(yep_serial_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(yep_serial_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(yep_serial_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(yep_serial_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(yep_serial_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(yep_serial_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(yep_serial_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(yep_serial_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(yep_serial_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(yep_serial_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(yep_serial_ENABLE_PCH "Enable precompiled headers" OFF)
    option(yep_serial_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      yep_serial_ENABLE_IPO
      yep_serial_WARNINGS_AS_ERRORS
      yep_serial_ENABLE_USER_LINKER
      yep_serial_ENABLE_SANITIZER_ADDRESS
      yep_serial_ENABLE_SANITIZER_LEAK
      yep_serial_ENABLE_SANITIZER_UNDEFINED
      yep_serial_ENABLE_SANITIZER_THREAD
      yep_serial_ENABLE_SANITIZER_MEMORY
      yep_serial_ENABLE_UNITY_BUILD
      yep_serial_ENABLE_CLANG_TIDY
      yep_serial_ENABLE_CPPCHECK
      yep_serial_ENABLE_COVERAGE
      yep_serial_ENABLE_PCH
      yep_serial_ENABLE_CACHE)
  endif()

  yep_serial_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (yep_serial_ENABLE_SANITIZER_ADDRESS OR yep_serial_ENABLE_SANITIZER_THREAD OR yep_serial_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(yep_serial_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(yep_serial_global_options)
  if(yep_serial_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    yep_serial_enable_ipo()
  endif()

  yep_serial_supports_sanitizers()

  if(yep_serial_ENABLE_HARDENING AND yep_serial_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR yep_serial_ENABLE_SANITIZER_UNDEFINED
       OR yep_serial_ENABLE_SANITIZER_ADDRESS
       OR yep_serial_ENABLE_SANITIZER_THREAD
       OR yep_serial_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${yep_serial_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${yep_serial_ENABLE_SANITIZER_UNDEFINED}")
    yep_serial_enable_hardening(yep_serial_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(yep_serial_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(yep_serial_warnings INTERFACE)
  add_library(yep_serial_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  yep_serial_set_project_warnings(
    yep_serial_warnings
    ${yep_serial_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(yep_serial_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(yep_serial_options)
  endif()

  include(cmake/Sanitizers.cmake)
  yep_serial_enable_sanitizers(
    yep_serial_options
    ${yep_serial_ENABLE_SANITIZER_ADDRESS}
    ${yep_serial_ENABLE_SANITIZER_LEAK}
    ${yep_serial_ENABLE_SANITIZER_UNDEFINED}
    ${yep_serial_ENABLE_SANITIZER_THREAD}
    ${yep_serial_ENABLE_SANITIZER_MEMORY})

  set_target_properties(yep_serial_options PROPERTIES UNITY_BUILD ${yep_serial_ENABLE_UNITY_BUILD})

  if(yep_serial_ENABLE_PCH)
    target_precompile_headers(
      yep_serial_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(yep_serial_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    yep_serial_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(yep_serial_ENABLE_CLANG_TIDY)
    yep_serial_enable_clang_tidy(yep_serial_options ${yep_serial_WARNINGS_AS_ERRORS})
  endif()

  if(yep_serial_ENABLE_CPPCHECK)
    yep_serial_enable_cppcheck(${yep_serial_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(yep_serial_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    yep_serial_enable_coverage(yep_serial_options)
  endif()

  if(yep_serial_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(yep_serial_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(yep_serial_ENABLE_HARDENING AND NOT yep_serial_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR yep_serial_ENABLE_SANITIZER_UNDEFINED
       OR yep_serial_ENABLE_SANITIZER_ADDRESS
       OR yep_serial_ENABLE_SANITIZER_THREAD
       OR yep_serial_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    yep_serial_enable_hardening(yep_serial_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
