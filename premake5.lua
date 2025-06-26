-- premake5.lua

local vkSdk = os.getenv("VULKAN_SDK")
if not vkSdk then
   error("VULKAN_SDK environment variable is not set!")
end

newoption {
   trigger     = "static",
   description = "Build NRI as a static library (default builds shared)"
}

-------------------------------------------------------------------------
-- 1) Declare the one-and-only workspace "NRI"
-------------------------------------------------------------------------
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
        "WIN32",                -- pull in <Windows.h> paths
        "VK_USE_PLATFORM_WIN32_KHR",
        "WIN32_LEAN_AND_MEAN",
        "NOMINMAX",
        "_CRT_SECURE_NO_WARNINGS",
      }
      -- ensure we include the system Vulkan headers *before* any stub
      includedirs { path.join(vkSdk, "Include") }
      libdirs     { path.join(vkSdk, "Lib") }
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

-------------------------------------------------------------------------
-- 2) Bring in each external premake5.lua *without* letting it hijack the workspace
-------------------------------------------------------------------------
group "Externals"
   -- stash the real functions
   local real_workspace    = workspace
   local real_startproject = startproject

   -- stub them out
   workspace    = function() end
   startproject = function() end

   -- now includes will *not* generate their own .sln or switch workspaces
   include "external/VMA/premake5.lua"                  -- D3D12MemoryAllocator
   include "external/NVTX/premake5.lua"                 -- NVTX
   include "external/VulkanHeaders/premake5.lua"        -- Vulkan-Headers
   include "external/VulkanMemoryAllocator/premake5.lua"-- VMA for Vulkan

   -- restore
   workspace    = real_workspace
   startproject = real_startproject
group ""

-------------------------------------------------------------------------
-- 3) Any pure‐lib SDKs you just link to directly
-------------------------------------------------------------------------
-- (e.g. AGS, NVAPI, DLSS/NGX, XeSS)
filter "system:windows"
   libdirs {
      "external/AMDAGS/ags_lib/lib",
      "external/NVAPI/amd64",          -- or x64
      "external/XESS/lib",
      "external/DLSS/lib/Windows_x86_64/x64"  -- both Debug/Release under same folder
   }
   links {
      "amd_ags_x64",    -- AMD AGS
      "nvapi64",        -- NVAPI
      "libxess",        -- XeSS
      -- ng d = debug, ng s = release suffix:
      "%{cfg.buildcfg == 'Debug' and 'nvsdk_ngx_d' or 'nvsdk_ngx_s'}"
   }
filter {}

-------------------------------------------------------------------------
-- 4) NRI_Shared
-------------------------------------------------------------------------
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
      path.join(vkSdk, "Include"),
      "external/VMA/include",
      "external/VulkanHeaders/include",
      "external/VulkanMemoryAllocator/include",
      "external/NVTX/c/include",
      "external/NVAPI",                -- nvapi.h
      "external/AMDAGS/ags_lib/inc",
      "external/DLSS/include",
      "external/XESS/inc/xess"
   }

   filter "system:windows"
      links { "vulkan-1" }                  -- link the Vulkan loader
   filter {}

-------------------------------------------------------------------------
-- 5) NRI (the final API library)
-------------------------------------------------------------------------
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

   -- export symbols
   if not buildStatic then
      filter "system:windows"
         defines { 'NRI_API=extern "C" __declspec(dllexport)' }
         links { "vulkan-1" }
      filter "system:not windows"
         defines { 'NRI_API=extern "C" __attribute__((visibility("default")))' }
      filter {}
   end

   -- on non-Windows pull in dl
   filter "system:not windows"
      links { "dl" }
   filter {}