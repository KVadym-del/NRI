
local vulkan_sdk = os.getenv("VULKAN_SDK")
if not vulkan_sdk then
  error("VULKAN_SDK environment variable is not set. Please set it to the path of your Vulkan SDK.")
end

workspace "NRI-SDK"
  architecture "x86_64"
  startproject "NRI"

  configurations { "Debug", "Release" }
  outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"

  systemversion "latest"

  filter "system:windows"
    defines {
      "WIN32_LEAN_AND_MEAN",
      "NOMINMAX",
      "_CRT_SECURE_NO_WARNINGS"
    }
  filter {}

  newoption {
    trigger = "NRI_STATIC_LIBRARY",
    description = "Build NRI as a static library instead of a shared library",
    value = "false"
  }
  newoption {
    trigger = "NRI_ENABLE_VK_SUPPORT",
    description = "Enable the Vulkan backend",
    value = "true"
  }
  newoption {
    trigger = "NRI_ENABLE_D3D12_SUPPORT",
    description = "Enable the D3D12 backend (Windows only)",
    value = "true"
  }
  newoption {
    trigger = "NRI_ENABLE_D3D11_SUPPORT",
    description = "Enable the D3D11 backend (Windows only)",
    value = "true"
  }
  newoption {
    trigger = "NRI_ENABLE_VALIDATION_SUPPORT",
    description = "Enable the Validation layer backend",
    value = "true"
  }
  newoption {
    trigger = "NRI_ENABLE_D3D_EXTENSIONS",
    description = "Enable vendor extensions for D3D (NVAPI and AMD AGS)",
    value = "true"
  }
  newoption {
    trigger = "NRI_ENABLE_NGX_SUPPORT",
    description = "Enable NVIDIA NGX (DLSS) SDK support",
    value = "true"
  }
  newoption {
    trigger = "NRI_ENABLE_XESS_SUPPORT",
    description = "Enable Intel XeSS SDK support",
    value = "true"
  }
  newoption {
    trigger = "NRI_ENABLE_NVTX_SUPPORT",
    description = "Enable NVIDIA NVTX annotation support",
    value = "true"
  }

  include "external/AGS_SDK"
  include "external/D3D12MemoryAllocator"
  include "external/DLSS"
  include "external/nvapi"
  include "external/NVTX"
  include "external/Vulkan-Headers"
  include "external/VulkanMemoryAllocator"
  include "external/xess"

project "NRI_Shared"
  kind "StaticLib"
  language "C++"
  cppdialect "C++17"

  targetdir ("bin/" .. outputdir .. "/%{prj.name}")
  objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

  files {
    "Source/Shared/**.cpp",
    "Source/Shared/**.h",
    "Source/Shared/**.hpp"
  }

  includedirs {
    "Include",
    "Source/Shared",
    "%{wks.location}/external/Vulkan-Headers/include",
  }

  filter "system:windows"
    links { "Kernel32" }
  filter {}

  filter "options:NRI_ENABLE_VK_SUPPORT=true"
    links { "Vulkan-Headers" }
    defines { "NRI_ENABLE_VK_SUPPORT=1" }

  filter "options:NRI_ENABLE_D3D11_SUPPORT=true"
    defines { "NRI_ENABLE_D3D11_SUPPORT=1" }

  filter "options:NRI_ENABLE_D3D12_SUPPORT=true"
    defines { "NRI_ENABLE_D3D12_SUPPORT=1" }

  filter "options:NRI_ENABLE_NVTX_SUPPORT=true"
    links { "NVTX" }
    defines { "NRI_ENABLE_NVTX_SUPPORT=1" }

  filter "options:NRI_ENABLE_NGX_SUPPORT=true"
    links { "DLSS" }
    defines { "NRI_ENABLE_NGX_SUPPORT=1" }

  filter "options:NRI_ENABLE_XESS_SUPPORT=true"
    links { "XeSS" }
    defines { "NRI_ENABLE_XESS_SUPPORT=1" }

  filter {}


if _OPTIONS["NRI_ENABLE_VK_SUPPORT"] == "true" then
  project "NRI_VK"
    kind "StaticLib"
    language "C++"
    cppdialect "C++17"
    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

    files { "Source/VK/**.cpp", "Source/VK/**.h", "Source/VK/**.hpp" }
    includedirs { 
      "Include",
      "Source/Shared",
      vulkan_sdk .. "/Include",
      "%{wks.location}/external/Vulkan-Headers/include",
      "%{wks.location}/external/VulkanMemoryAllocator/include"
    }
    links { "NRI_Shared", "VulkanMemoryAllocator" }
    defines { "NRI_ENABLE_VK_SUPPORT=1" }
end

if _OPTIONS["NRI_ENABLE_D3D12_SUPPORT"] == "true" then
  project "NRI_D3D12"
    kind "StaticLib"
    language "C++"
    cppdialect "C++17"
    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

    files { "Source/D3D12/**.cpp", "Source/D3D12/**.h" }
    includedirs { 
      "Include",
      "Source/Shared",
      "%{wks.location}/external/AGS_SDK/ags_lib/inc",
      "%{wks.location}/external/nvapi",
      "%{wks.location}/external/D3D12MemoryAllocator/include",
      "%{wks.location}/external/D3D12MemoryAllocator/src"
    }
    links { "NRI_Shared", "D3D12MemoryAllocator" }
    defines { "NRI_ENABLE_D3D12_SUPPORT=1" }

    filter "options:NRI_ENABLE_D3D_EXTENSIONS=true"
      links { "NVAPI", "AGS_SDK" }
      defines { "NRI_ENABLE_D3D_EXTENSIONS=1" }
end

if _OPTIONS["NRI_ENABLE_D3D11_SUPPORT"] == "true" then
  project "NRI_D3D11"
    kind "StaticLib"
    language "C++"
    cppdialect "C++17"
    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

    files { "Source/D3D11/**.cpp", "Source/D3D11/**.h" }
    includedirs { 
      "Include",
      "Source/Shared",
      "%{wks.location}/external/AGS_SDK/ags_lib/inc",
      "%{wks.location}/external/nvapi"
    }
    links { "NRI_Shared" }
    defines { "NRI_ENABLE_D3D11_SUPPORT=1" }

    filter "options:NRI_ENABLE_D3D_EXTENSIONS=true"
      links { "NVAPI", "AGS_SDK" }
      defines { "NRI_ENABLE_D3D_EXTENSIONS=1" }
end

if _OPTIONS["NRI_ENABLE_VALIDATION_SUPPORT"] == "true" then
  project "NRI_Validation"
    kind "StaticLib"
    language "C++"
    cppdialect "C++17"
    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

    files { "Source/Validation/**.cpp", "Source/Validation/**.h" }
    includedirs { "Include", "Source/Shared" }
    links { "NRI_Shared" }
    defines { "NRI_ENABLE_VALIDATION_SUPPORT=1" }
end

project "NRI"
  language "C++"
  cppdialect "C++17"

  targetdir ("bin/" .. outputdir .. "/%{prj.name}")
  objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

  filter "options:NRI_STATIC_LIBRARY=true"
    kind "StaticLib"
    defines { "NRI_STATIC_LIBRARY=1" }
  filter "options:NRI_STATIC_LIBRARY=false"
    kind "SharedLib"
    defines { "NRI_EXPORT" }
  filter {}

  files {
    "Source/Creation/**.cpp",
    "Source/Creation/**.h",
    "Include/**.h",
    "Include/Extensions/**.h",
    "Include/Extensions/**.hpp"
  }

  includedirs {
    "Include",
    "Source/Shared",
    "%{wks.location}/external/Vulkan-Headers/include",
  }

  links { "NRI_Shared" }
  if _OPTIONS["NRI_ENABLE_VK_SUPPORT"] == "true" then links { "NRI_VK" } defines { "NRI_ENABLE_VK_SUPPORT=1" } end -- CORRECTED
  if _OPTIONS["NRI_ENABLE_D3D12_SUPPORT"] == "true" then links { "NRI_D3D12" } defines { "NRI_ENABLE_D3D12_SUPPORT=1" } end -- CORRECTED
  if _OPTIONS["NRI_ENABLE_D3D11_SUPPORT"] == "true" then links { "NRI_D3D11" } defines { "NRI_ENABLE_D3D11_SUPPORT=1" } end -- CORRECTED
  if _OPTIONS["NRI_ENABLE_VALIDATION_SUPPORT"] == "true" then links { "NRI_Validation" } defines { "NRI_ENABLE_VALIDATION_SUPPORT=1" } end -- CORRECTED

  filter "options:NRI_ENABLE_D3D_EXTENSIONS=true"
    links { "NVAPI", "AGS_SDK" }
  filter {}

  filter "system:windows"
    links { "d3d12", "d3d11", "dxgi", "d3dcompiler", "dxguid" }
  filter {}

  filter "system:windows"
    postbuildcommands {
      '{COPY} "%{wks.location}/external/AGS_SDK/ags_lib/lib/amd_ags_x64.dll" "%{cfg.targetdir}"',
      '{COPY} "%{wks.location}/external/DLSS/lib/Windows_x86_64/rel/nvngx_dlssd.dll" "%{cfg.targetdir}"',
      '{COPY} "%{wks.location}/external/DLSS/lib/Windows_x86_64/rel/nvngx_dlss.dll" "%{cfg.targetdir}"',
      '{COPY} "%{wks.location}/external/xess/bin/libxess.dll" "%{cfg.targetdir}"'
    }


-- premake5 vs2022 --NRI_STATIC_LIBRARY=false --NRI_ENABLE_VK_SUPPORT=true --NRI_ENABLE_D3D12_SUPPORT=true --NRI_ENABLE_D3D11_SUPPORT=true --NRI_ENABLE_VALIDATION_SUPPORT=true --NRI_ENABLE_D3D_EXTENSIONS=true --NRI_ENABLE_NGX_SUPPORT=true --NRI_ENABLE_XESS_SUPPORT=true --NRI_ENABLE_NVTX_SUPPORT=true
-- MSBuild.exe NRI-SDK.sln /t:Rebuild /p:Configuration=Release /p:Platform=x64 /m /p:VcpkgEnabled=false