#!/usr/bin/env texlua

-- Build script for LaTeX2e "base" files

-- Identify the bundle and module
module = "base"
bundle = ""

-- CTAN's name for this is a bit different from ours
ctanpkg = "latex-base"

-- Location of main directory: use Unix-style path separators
maindir = ".."

-- Set up the file types needed here
installfiles   =
  {
    "*.cfg",
    "*.clo",
    "*.cls",
    "*.def",
    "*.dfu",
    "*.fd",
    "*.ltx",
    "*.lua",
    "*.sty",
    "*.tex"
  }
sourcefiles    = {"*.cls", "unicode-letters.def", "*.dtx", "*.fdd", "*.ins", "*.tex"}
typesetfiles   =
  {
    "source2e.tex",
    "alltt.dtx",
    "classes.dtx",
    "cmfonts.dtx",
    "doc.dtx",
    "docstrip.dtx",
    "exscale.dtx",
    "fix-cm.dtx",
    "graphpap.dtx",
    "ifthen.dtx",
    "inputenc.dtx",
    "ltunicode.dtx",
    "lppl.tex",
    "utf8ienc.dtx",
    "latexrelease.dtx",
    "latexsym.dtx",
    "letter.dtx",
    "ltluatex.dtx",
    "ltxdoc.dtx",
    "makeindx.dtx",
    "nfssfont.dtx",
    "proc.dtx",
    "slides.dtx",
    "slifonts.dtx",
    "syntonly.dtx",
    "*.fdd",
    "*.err",
  }

-- A few special file for unpacking
unpackfiles     = {"unpack.ins"}
unpacksuppfiles = {"hyphen.cfg", "UShyphen.tex"}

-- Custom settings for the check system
testsuppdir = "testfiles/helpers"

-- No dependencies at all (other than l3build of course)
checkdeps  = { }
unpackdeps = { }

-- Customise typesetting
indexstyle = "source2e.ist"

function format ()
  local errorlevel = unpack ()
  if errorlevel ~=0 then
    return errorlevel
  end
  local function format (engine,fmtname)
    -- the relationships are all correct
    local errorlevel = os.execute (
        os_setenv .. " TEXINPUTS=" .. unpackdir .. os_pathsep .. localdir
        .. os_concat ..
        engine .. " -etex -ini " .. " -output-directory=" .. unpackdir ..
        " " .. unpackdir .. "/latex.ltx"
      )
    if errorlevel ~=0 then
      return errorlevel
    end
    ren (unpackdir, "latex.fmt", fmtname)
    -- As format building is added in as an 'extra', the normal
    -- copy mechanism (checkfiles) will fail as things get cleaned up
    -- inside bundleunpack(): get around that using a manual copy
    cp (fmtname, unpackdir, localdir)
    if fmtname == "elatex.fmt" then
      rm(localdir, "latex.fmt")
      ren(localdir, fmtname, "latex.fmt")
    end
    return 0
  end
  local checkengines = optengines or checkengines
  for _,i in ipairs(checkengines) do
    errorlevel = format (i, string.gsub (i, "tex$", "") .. "latex.fmt")
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  return 0
end

-- Custom bundleunpack which does not search the localdir
-- That is needed as texsys.cfg is unpacked in an odd way and
-- without this will otherwise not be available
function bundleunpack () 
  local errorlevel = mkdir(localdir)
  if errorlevel ~=0 then
    return errorlevel
  end
  errorlevel = cleandir(unpackdir)
  if errorlevel ~=0 then
    return errorlevel
  end
  for _,i in ipairs (sourcefiles) do
    errorlevel = cp (i, ".", unpackdir)
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  for _,i in ipairs (unpacksuppfiles) do
    errorlevel = cp (i, supportdir, localdir)
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  for _,i in ipairs (unpackfiles) do
    for _,j in ipairs (filelist (unpackdir, i)) do
      os.execute (os_yes .. ">>" .. localdir .. "/yes")
      errorlevel = os.execute (
          -- Notice that os.execute is used from 'here' as this ensures that
          -- localdir points to the correct place: running 'inside'
          -- unpackdir would avoid the need for setting -output-directory
          -- but at the cost of needing to correct the relative position
          -- of localdir w.r.t. unpackdir
          os_setenv .. " TEXINPUTS=" .. unpackdir .. os_concat ..
          unpackexe .. " " .. unpackopts .. " -output-directory=" .. unpackdir
            .. " " .. unpackdir .. "/" .. j .. " < " .. localdir .. "/yes"
        )
      if errorlevel ~=0 then
        return errorlevel
      end
    end
  end
  return 0
end

-- base does all of the targets itself
function main (target, file, engine)
  local errorlevel
  if target == "check" then
    format ()
    errorlevel = check (file, engine)
  elseif target == "clean" then
    errorlevel = clean ()
  elseif target == "ctan" then
    format ()
    errorlevel = ctan (true)
  elseif target == "doc" then
    errorlevel = doc ()
  elseif target == "install" then
    install ()
  elseif target == "save" then
    if file then
      errorlevel = save (file, engine)
    else
      help ()
    end
  elseif target == "unpack" then
    -- A simple way to have the unpack target also build the format
    errorlevel = format ()
  elseif target == "version" then
    version ()
  else
    help ()
  end
  os.exit (errorlevel)
end

-- Load the common settings for the LaTeX2e repo
dofile (maindir .. "/build-config.lua")

-- Find and run the build system
kpse.set_program_name ("kpsewhich")
dofile (kpse.lookup ("l3build.lua"))
