#
# Open3D 3rd party library integration
#
set(Open3D_3RDPARTY_DIR "${PROJECT_SOURCE_DIR}/3rdparty")

# EXTERNAL_MODULES
# CMake modules we depend on in our public interface. These are modules we
# need to find_package() in our CMake config script, because we will use their
# targets.
set(Open3D_3RDPARTY_EXTERNAL_MODULES)

# PUBLIC_TARGETS
# CMake targets we link against in our public interface. They are
# either locally defined and installed, or imported from an external module
# (see above).
set(Open3D_3RDPARTY_PUBLIC_TARGETS)

# HEADER_TARGETS
# CMake targets we use in our public interface, but as a special case we do not
# need to link against the library. This simplifies dependencies where we merely
# expose declared data types from other libraries in our public headers, so it
# would be overkill to require all library users to link against that dependency.
set(Open3D_3RDPARTY_HEADER_TARGETS)

# PRIVATE_TARGETS
# CMake targets for dependencies which are not exposed in the public API. This
# will probably include HEADER_TARGETS, but also anything else we use internally.
set(Open3D_3RDPARTY_PRIVATE_TARGETS)

find_package(PkgConfig QUIET)

#
# build_3rdparty_library(name ...)
#
# Builds a third-party library from source
#
# Valid options:
#    PUBLIC
#        the library belongs to the public interface and must be installed
#    HEADER
#        the library headers belong to the public interface, but the library
#        itself is linked privately
#    INCLUDE_ALL
#        install all files in the include directories. Default is *.h, *.hpp
#    DIRECTORY <dir>
#        the library sources are in the subdirectory <dir> of 3rdparty/
#    INCLUDE_DIRS <dir> [<dir> ...]
#        include headers are in the subdirectories <dir>. Trailing slashes
#        have the same meaning as with install(DIRECTORY). <dir> must be
#        relative to the library source directory.
#        If your include is "#include <x.hpp>" and the path of the file is
#        "path/to/libx/x.hpp" then you need to pass "path/to/libx/"
#        with the trailing "/". If you have "#include <libx/x.hpp>" then you
#        need to pass "path/to/libx".
#    SOURCES <src> [<src> ...]
#        the library sources. Can be omitted for header-only libraries.
#        All sources must be relative to the library source directory.
#    LIBS <target> [<target> ...]
#        extra link dependencies
#
function(build_3rdparty_library name)
    cmake_parse_arguments(arg "PUBLIC;HEADER;INCLUDE_ALL" "DIRECTORY" "INCLUDE_DIRS;SOURCES;LIBS" ${ARGN})
    if(arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Invalid syntax: build_3rdparty_library(${name} ${ARGN})")
    endif()
    if(NOT arg_DIRECTORY)
        set(arg_DIRECTORY "${name}")
    endif()
    if(arg_INCLUDE_DIRS)
        set(include_dirs)
        foreach(incl IN LISTS arg_INCLUDE_DIRS)
            list(APPEND include_dirs "${Open3D_3RDPARTY_DIR}/${arg_DIRECTORY}/${incl}")
        endforeach()
    else()
        set(include_dirs "${Open3D_3RDPARTY_DIR}/${arg_DIRECTORY}/")
    endif()
    message(STATUS "Building library ${name} from source")
    if(arg_SOURCES)
        set(sources)
        foreach(src ${arg_SOURCES})
            list(APPEND sources "${Open3D_3RDPARTY_DIR}/${arg_DIRECTORY}/${src}")
        endforeach()
        add_library(${name} STATIC ${sources})
        foreach(incl IN LISTS include_dirs)
            if (incl MATCHES "(.*)/$")
                set(incl_path ${CMAKE_MATCH_1})
            else()
                get_filename_component(incl_path "${incl}" DIRECTORY)
            endif()
            target_include_directories(${name} SYSTEM PUBLIC
                $<BUILD_INTERFACE:${incl_path}>
            )
        endforeach()
        target_include_directories(${name} PUBLIC
            $<INSTALL_INTERFACE:${Open3D_INSTALL_INCLUDE_DIR}/open3d/3rdparty>
        )
        open3d_set_global_properties(${name})
        set_target_properties(${name} PROPERTIES
            OUTPUT_NAME "${PROJECT_NAME}_${name}"
        )
        if(arg_LIBS)
            target_link_libraries(${name} PRIVATE ${arg_LIBS})
        endif()
    else()
        add_library(${name} INTERFACE)
        foreach(incl IN LISTS include_dirs)
            if (incl MATCHES "(.*)/$")
                set(incl_path ${CMAKE_MATCH_1})
            else()
                get_filename_component(incl_path "${incl}" DIRECTORY)
            endif()
            target_include_directories(${name} SYSTEM INTERFACE
                $<BUILD_INTERFACE:${incl_path}>
            )
        endforeach()
        target_include_directories(${name} INTERFACE
            $<INSTALL_INTERFACE:${Open3D_INSTALL_INCLUDE_DIR}/open3d/3rdparty>
        )
    endif()
    if(NOT BUILD_SHARED_LIBS OR arg_PUBLIC)
        install(TARGETS ${name} EXPORT ${PROJECT_NAME}Targets
            RUNTIME DESTINATION ${Open3D_INSTALL_BIN_DIR}
            ARCHIVE DESTINATION ${Open3D_INSTALL_LIB_DIR}
            LIBRARY DESTINATION ${Open3D_INSTALL_LIB_DIR}
        )
    endif()
    if(arg_PUBLIC OR arg_HEADER)
        foreach(incl IN LISTS include_dirs)
            if(arg_INCLUDE_ALL)
                install(DIRECTORY ${incl}
                    DESTINATION ${Open3D_INSTALL_INCLUDE_DIR}/open3d/3rdparty
                )
            else()
                install(DIRECTORY ${incl}
                    DESTINATION ${Open3D_INSTALL_INCLUDE_DIR}/open3d/3rdparty
                    FILES_MATCHING
                        PATTERN "*.h"
                        PATTERN "*.hpp"
                )
            endif()
        endforeach()
    endif()
    add_library(${PROJECT_NAME}::${name} ALIAS ${name})
endfunction()

#
# pkg_config_3rdparty_library(name ...)
#
# Creates an interface library for a pkg-config dependency.
# All arguments are passed verbatim to pkg_search_module()
#
# The function will set ${name}_FOUND to TRUE or FALSE
# indicating whether or not the library could be found.
#
function(pkg_config_3rdparty_library name)
    if(PKGCONFIG_FOUND)
        pkg_search_module(pc_${name} ${ARGN})
    endif()
    if(pc_${name}_FOUND)
        message(STATUS "Using installed third-party library ${name} ${${name_uc}_VERSION}")
        add_library(${name} INTERFACE)
        target_include_directories(${name} SYSTEM INTERFACE ${pc_${name}_INCLUDE_DIRS})
        target_link_libraries(${name} INTERFACE ${pc_${name}_LINK_LIBRARIES})
        foreach(flag IN LISTS pc_${name}_CFLAGS_OTHER)
            if(flag MATCHES "-D(.*)")
                target_compile_definitions(${name} INTERFACE ${CMAKE_MATCH_1})
            endif()
        endforeach()
        install(TARGETS ${name} EXPORT ${PROJECT_NAME}Targets)
        set(${name}_FOUND TRUE PARENT_SCOPE)
        add_library(${PROJECT_NAME}::${name} ALIAS ${name})
    else()
        message(STATUS "Unable to find installed third-party library ${name}")
        set(${name}_FOUND FALSE PARENT_SCOPE)
    endif()
endfunction()

#
# import_3rdparty_library(name ...)
#
# Imports a third-party library that has been built independently in a sub project.
#
# Valid options:
#    PUBLIC
#        the library belongs to the public interface and must be installed
#    HEADER
#        the library headers belong to the public interface and will be
#        installed, but the library is linked privately.
#    INCLUDE_DIRS
#        the temporary location where the library headers have been installed.
#        Trailing slashes have the same meaning as with install(DIRECTORY).
#        If your include is "#include <x.hpp>" and the path of the file is
#        "/path/to/libx/x.hpp" then you need to pass "/path/to/libx/"
#        with the trailing "/". If you have "#include <libx/x.hpp>" then you
#        need to pass "/path/to/libx".
#    LIBRARIES
#        the built library name(s). It is assumed that the library is static.
#        If the library is PUBLIC, it will be renamed to Open3D_${name} at
#        install time to prevent name collisions in the install space.
#    LIB_DIR
#        the temporary location of the library. Defaults to
#        CMAKE_ARCHIVE_OUTPUT_DIRECTORY.
#
function(import_3rdparty_library name)
    cmake_parse_arguments(arg "PUBLIC;HEADER" "LIB_DIR" "INCLUDE_DIRS;LIBRARIES" ${ARGN})
    if(arg_UNPARSED_ARGUMENTS)
        message(STATUS "Unparsed: ${arg_UNPARSED_ARGUMENTS}")
        message(FATAL_ERROR "Invalid syntax: import_3rdparty_library(${name} ${ARGN})")
    endif()
    if(NOT arg_LIB_DIR)
        set(arg_LIB_DIR "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}")
    endif()
    add_library(${name} INTERFACE)
    if(arg_INCLUDE_DIRS)
        foreach(incl IN LISTS arg_INCLUDE_DIRS)
            if (incl MATCHES "(.*)/$")
                set(incl_path ${CMAKE_MATCH_1})
            else()
                get_filename_component(incl_path "${incl}" DIRECTORY)
            endif()
            target_include_directories(${name} SYSTEM INTERFACE $<BUILD_INTERFACE:${incl_path}>)
            if(arg_PUBLIC OR arg_HEADER)
                install(DIRECTORY ${incl} DESTINATION ${Open3D_INSTALL_INCLUDE_DIR}/open3d/3rdparty
                    FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
                )
                target_include_directories(${name} INTERFACE $<INSTALL_INTERFACE:${Open3D_INSTALL_INCLUDE_DIR}/open3d/3rdparty>)
            endif()
        endforeach()
    endif()
    if(arg_LIBRARIES)
        list(LENGTH arg_LIBRARIES libcount)
        foreach(arg_LIBRARY IN LISTS arg_LIBRARIES)
            set(library_filename ${CMAKE_STATIC_LIBRARY_PREFIX}${arg_LIBRARY}${CMAKE_STATIC_LIBRARY_SUFFIX})
            if(libcount EQUAL 1)
                set(installed_library_filename ${CMAKE_STATIC_LIBRARY_PREFIX}${PROJECT_NAME}_${name}${CMAKE_STATIC_LIBRARY_SUFFIX})
            else()
                set(installed_library_filename ${CMAKE_STATIC_LIBRARY_PREFIX}${PROJECT_NAME}_${name}_${arg_LIBRARY}${CMAKE_STATIC_LIBRARY_SUFFIX})
            endif()
            target_link_libraries(${name} INTERFACE $<BUILD_INTERFACE:${arg_LIB_DIR}/${library_filename}>)
            if(NOT BUILD_SHARED_LIBS OR arg_PUBLIC)
                install(FILES ${arg_LIB_DIR}/${library_filename}
                    DESTINATION ${Open3D_INSTALL_LIB_DIR}
                    RENAME ${installed_library_filename}
                )
                target_link_libraries(${name} INTERFACE $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${Open3D_INSTALL_LIB_DIR}/${installed_library_filename}>)
            endif()
        endforeach()
    endif()
    if(NOT BUILD_SHARED_LIBS OR arg_PUBLIC)
        install(TARGETS ${name} EXPORT ${PROJECT_NAME}Targets)
    endif()
    add_library(${PROJECT_NAME}::${name} ALIAS ${name})
endfunction()

#
# set_local_or_remote_url(url ...)
#
# If LOCAL_URL exists, set URL to LOCAL_URL, otherwise set URL to REMOTE_URLS.
# This function is needed since CMake does not allow specifying remote URL(s) if
# a local URL is specified.
#
# Valid options:
#    LOCAL_URL
#        local url to a file. Optional parameter. If the file does not exist,
#        LOCAL_URL will be ignored. If the file exists, REMOTE URLS will be
#        ignored. CMake only allows setting single LOCAL_URL for external
#        projects.
#    REMOTE_URLS
#        remote url(s) to download a file. CMake will try to download the file
#        in the specified order.
#
function(set_local_or_remote_url URL)
    cmake_parse_arguments(arg "" "LOCAL_URL" "REMOTE_URLS" ${ARGN})
    if(arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Invalid syntax: set_local_or_remote_url(${name} ${ARGN})")
    endif()
    if(arg_LOCAL_URL AND (EXISTS ${arg_LOCAL_URL}))
        message(STATUS "Using local url: ${arg_LOCAL_URL}")
        set(${URL} "${arg_LOCAL_URL}" PARENT_SCOPE)
    else()
        message(STATUS "Using remote url(s): ${arg_REMOTE_URLS}")
        set(${URL} "${arg_REMOTE_URLS}" PARENT_SCOPE)
    endif()
endfunction()

# Threads
set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG TRUE) # -pthread instead of -lpthread
find_package(Threads REQUIRED)
list(APPEND Open3D_3RDPARTY_EXTERNAL_MODULES "Threads")

# OpenMP
if(WITH_OPENMP)
    find_package(OpenMP)
    if(TARGET OpenMP::OpenMP_CXX)
        message(STATUS "Building with OpenMP")
        set(OPENMP_TARGET "OpenMP::OpenMP_CXX")
        list(APPEND Open3D_3RDPARTY_PRIVATE_TARGETS "${OPENMP_TARGET}")
        if(NOT BUILD_SHARED_LIBS)
            list(APPEND Open3D_3RDPARTY_EXTERNAL_MODULES "OpenMP")
        endif()
    endif()
endif()


# Pybind11
if(USE_SYSTEM_PYBIND11)
    find_package(pybind11)
endif()
if (NOT USE_SYSTEM_PYBIND11 OR NOT TARGET pybind11::module)
    set(USE_SYSTEM_PYBIND11 OFF)
    add_subdirectory(${Open3D_3RDPARTY_DIR}/pybind11)
endif()
if(TARGET pybind11::module)
    set(PYBIND11_TARGET "pybind11::module")
endif()
