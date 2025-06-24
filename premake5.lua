workspace "NRI"
   architecture "x86_64"
   startproject "NRI"
   configurations { "Debug", "Release" }

outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"

-- CLI options
newoption {
   trigger     = "static",
   description = "Build NRI as a static library"
}
newoption {
   trigger     = "enable-d3d11",
   description = "Enable D3D11 backend (Windows only)"
}
newoption {
   trigger     = "enable-d3d12",
   description = "Enable D3D12 backend (Windows only)"
}
newoption {
   trigger     = "enable-vk",
   description = "Enable Vulkan backend"
}
newoption {
   trigger     = "enable-none",
   description = "Enable NONE (reference) backend"
}
newoption {
   trigger     = "enable-validation",
   description = "Enable Validation layers support"
}
newoption {
   trigger     = "vulkan-sdk",
   value       = "path",
   description = "Override VULKAN_SDK env‐var with this path"
}

local useStatic      = _OPTIONS["static"]            ~= nil
local enableD3D11    = os.host() == "windows"
                      and _OPTIONS["enable-d3d11"]   ~= nil
local enableD3D12    = os.host() == "windows"
                      and _OPTIONS["enable-d3d12"]   ~= nil
local enableVK       = _OPTIONS["enable-vk"]        ~= nil
local enableNone     = _OPTIONS["enable-none"]      ~= nil
local enableValidate = _OPTIONS["enable-validation"]~= nil

-- Vulkan SDK detection (required if --enable-vk)
local vulkan_sdk = _OPTIONS["vulkan-sdk"] or os.getenv("VULKAN_SDK")
if enableVK and not vulkan_sdk then
   error("Vulkan SDK not found: set VULKAN_SDK or pass --vulkan-sdk=path")
end

project "NRI"
   kind        ( useStatic and "StaticLib" or "SharedLib" )
   language    "C++"
   cppdialect  "C++17"
   staticruntime "On"

   targetdir ("bin/"    .. outputdir .. "/%{prj.name}")
   objdir    ("bin-int/".. outputdir .. "/%{prj.name}")

   includedirs {
      "Include",
      "Source/Shared",
   }

   files {
      "Include/**.h",
      "Include/**.hpp",
      "Source/Shared/**.cpp",
      "Source/Shared/**.h",
      "Source/Shared/**.hpp",
      "Source/Creation/**.cpp",
      "Source/Creation/**.h",
   }

   if enableNone then
      files { "Source/NONE/**.cpp", "Source/NONE/**.h" }
      defines { "NRI_ENABLE_NONE_SUPPORT=1" }
   end

   filter "system:windows"
      systemversion "latest"
      defines {
         "WIN32_LEAN_AND_MEAN",
         "NOMINMAX",
         "_CRT_SECURE_NO_WARNINGS",
         "UNICODE",
         "_UNICODE",
      }
      links { "user32", "gdi32" }

      if enableD3D11 then
         files { "Source/D3D11/**.cpp", "Source/D3D11/**.h" }
         defines { "NRI_ENABLE_D3D11_SUPPORT=1" }
         links { "d3d11", "dxgi", "dxguid" }
      end

      if enableD3D12 then
         files { "Source/D3D12/**.cpp", "Source/D3D12/**.h" }
         defines { "NRI_ENABLE_D3D12_SUPPORT=1" }
         links { "d3d12", "dxgi", "dxguid" }
      end

      if enableD3D11 or enableD3D12 then
         defines { "NRI_ENABLE_D3D_EXTENSIONS=1" }

         includedirs { "external/NVAPI" }
         libdirs    { "external/NVAPI/amd64" }
         links      { "nvapi64" }

         includedirs { "external/AMDAGS/ags_lib/inc" }
         libdirs    { "external/AMDAGS/ags_lib/lib" }
         links      { "amd_ags_x64" }
      end

      if enableD3D12 then
         includedirs {
            "external/VMA/include",
            "external/VMA/src",
         }
      end

      if enableVK then
         files { "Source/VK/**.cpp", "Source/VK/**.h" }
         defines { "NRI_ENABLE_VK_SUPPORT=1", "VK_USE_PLATFORM_WIN32_KHR" }

         includedirs {
            path.join(vulkan_sdk, "Include"),
            "external/VulkanMemoryAllocator/include",
         }
         libdirs { path.join(vulkan_sdk, "Lib") }
         links  { "vulkan-1" }
      end

      if enableValidate then
         files {
            "Source/Validation/**.cpp",
            "Source/Validation/**.h",
            "Source/Validation/**.hpp",
         }
         defines { "NRI_ENABLE_VALIDATION_SUPPORT=1" }
      end

   filter "system:linux"
      pic "On"
      defines { "POSIX", "NRI_ENABLE_NONE_SUPPORT=1" }
      links   { "pthread", "dl", "m" }

      if enableVK then
         files { "Source/VK/**.cpp", "Source/VK/**.h" }
         defines { "NRI_ENABLE_VK_SUPPORT=1", "VK_USE_PLATFORM_XLIB_KHR" }

         includedirs {
            path.join(vulkan_sdk, "Include"),
            "external/VulkanMemoryAllocator/include",
         }
         libdirs { path.join(vulkan_sdk, "Lib") }
         links  { "vulkan" }
      end

      if enableValidate then
         files {
            "Source/Validation/**.cpp",
            "Source/Validation/**.h",
            "Source/Validation/**.hpp",
         }
         defines { "NRI_ENABLE_VALIDATION_SUPPORT=1" }
      end

   filter "configurations:Debug"
      runtime "Debug"
      symbols "On"
      defines { "DEBUG" }

   filter "configurations:Release"
      runtime  "Release"
      optimize "Speed"
      defines  { "NDEBUG" }