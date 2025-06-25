-- premake5.lua

newoption {
   trigger     = "static",
   description = "Build NRI as a static library (default builds shared)"
}

workspace "NRI"
   configurations { "Debug", "Release" }
   platforms      { "x86", "x64" }
   startproject   "NRI"

   filter "platforms:x86"
      architecture "x86"
   filter "platforms:x64"
      architecture "x86_64"
   filter {}

   filter "system:windows"
      systemversion "latest"
      defines {
         "WIN32_LEAN_AND_MEAN",
         "NOMINMAX",
         "_CRT_SECURE_NO_WARNINGS"
      }
   filter {}

   filter "configurations:Debug"
      runtime "Debug"
      symbols "On"
   filter "configurations:Release"
      runtime "Release"
      optimize "On"
   filter {}

   targetdir "bin/%{cfg.buildcfg}_%{cfg.platform}"
   objdir    "bin-int/%{cfg.buildcfg}_%{cfg.platform}"

-- pull in your premake5.lua from those submodules
group "Externals"
   include "external/VMA/premake5.lua"                  -- D3D12MemAlloc
   include "external/NVTX/premake5.lua"                 -- NVTX
   include "external/VulkanHeaders/premake5.lua"        -- Vulkan-Headers
   include "external/VulkanMemoryAllocator/premake5.lua" -- VMA for Vulkan
group ""

--
-- NRI_Shared: all of the common code
--
project "NRI_Shared"
   kind "StaticLib"
   language "C++"
   cppdialect "C++17"
   staticruntime "On"

   files {
      "Source/Shared/**.cpp",
      "Source/Shared/**.h",
      "Source/Shared/**.hpp"
   }

   includedirs {
      "Include",
      "external/VMA/include",
      "external/VulkanHeaders/include",
      "external/VulkanMemoryAllocator/include",
      "external/NVTX/c/include",
      "external/NVAPI",                -- nvapi.h lives here
      "external/AMDAGS/ags_lib/inc",
      "external/DLSS/include",         -- assume DLSS headers here
      "external/XESS/inc/xess"
   }

filter {}

--
-- NRI: the public API / final lib
--
local buildStatic = _OPTIONS["static"] ~= nil

project "NRI"
   kind ( buildStatic and "StaticLib" or "SharedLib" )
   language "C++"
   cppdialect "C++17"
   staticruntime "On"

   files {
      "Include/**.h",
      "Include/**.hpp",
      "Include/**.hlsl",
      "Source/Creation/**.cpp",
      "Source/Creation/**.h",
      "Resources/**"
   }

   includedirs {
      "Include",
      "Source/Shared"
   }

   links { "NRI_Shared" }

-- export symbols only in shared-lib mode
if not buildStatic then
   filter "system:windows"
      defines { 'NRI_API=extern "C" __declspec(dllexport)' }
   filter "system:not windows"
      defines { 'NRI_API=extern "C" __attribute__((visibility("default")))' }
   filter {}
end

-- third-party SDK libs (Windows only)
filter "system:windows"
   libdirs {
      "external/AMDAGS/ags_lib/lib",
      "external/NVAPI",
      "external/XESS/lib"
   }
   links {
      "amd_ags_x64",  -- AMD AGS
      "nvapi64",      -- NVAPI
      "libxess"       -- XeSS
   }
filter {}

-- DLSS/NGX: debug vs release
filter { "system:windows", "configurations:Debug" }
   libdirs { "external/DLSS/lib/Windows_x86_64/x64/dev" }
   links   { "nvsdk_ngx_d" }
filter { "system:windows", "configurations:Release" }
   libdirs { "external/DLSS/lib/Windows_x86_64/x64/rel" }
   links   { "nvsdk_ngx" }
filter {}

-- on Linux/macOS just pull in dl for shared libs
filter "system:not windows"
   links { "dl" }
filter {}