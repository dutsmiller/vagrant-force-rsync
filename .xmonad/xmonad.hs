import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO
import XMonad.Hooks.SetWMName
import XMonad.Layout.Grid
import XMonad.Layout.ResizableTile
import XMonad.Layout.ThreeColumns
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.ComboP
import XMonad.Layout.TwoPane
import XMonad.Layout.Tabbed
import XMonad.Layout.LayoutCombinators hiding ((|||))
import XMonad.Hooks.ManageDocks
import qualified XMonad.StackSet as W


import XMonad hiding (Tall)
import XMonad.Actions.CycleWS
import XMonad.Actions.FloatKeys
import XMonad.Actions.GridSelect
import XMonad.Hooks.DynamicHooks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.ComboP
import XMonad.Layout.LayoutCombinators hiding ((|||))
import XMonad.Layout.LayoutHints
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.TwoPane
import XMonad.ManageHook
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Util.Run
import Control.Monad (liftM2)
import Data.Monoid
import Graphics.X11
import Graphics.X11.Xinerama
import System.Exit
import System.IO

import qualified XMonad.Actions.FlexibleResize as Flex
import qualified XMonad.StackSet as W
import qualified Data.Map as M



startup :: X ()
startup = do
          spawn "urxvt"
          spawn "thunderbird"
          spawn "icecat"

myWorkspaces =
  [
    "1:term", "2:web", "3:email", "4:gimp", "5", "6", "7", "8", "9:sound", ""
  ]

-- tabbedLayout = tabbedBottomAlways shrinkText defaultTheme

gimpLayout = smartBorders(avoidStruts(ThreeColMid 1 (3/100) (3/4)))
-- gimpLayout = combineTwoP (TwoPane 0.04 0.82) (tabbedLayout) (Full) (Not (Role "gimp-toolbox"))

defaultLayouts = smartBorders(avoidStruts(
  ResizableTall 1 (3/100) (1/2) []
  ||| Mirror (ResizableTall 1 (3/100) (1/2) [])
  ||| noBorders Full
  ||| Grid))


myLayouts =
  onWorkspace "4:gimp" gimpLayout
  $ defaultLayouts


myManageHook = composeAll
    [ className =? "Gimp"      --> doShift "4:gimp"
    , className =? "Icecat" --> doShift "2:web"
    , className =? "Thunderbird" --> doShift "3:email"
    , className =? "Vncviewer" --> doFloat
    ]



main = do
    xmproc <- spawnPipe "/usr/bin/xmobar /home/jbeaty/.xmobarrc"
    xmonad $ defaultConfig
        { manageHook = manageDocks <+> myManageHook -- make sure to include myManageHook definition from above
                        <+> manageHook defaultConfig
        , layoutHook = myLayouts
        , logHook = dynamicLogWithPP $ xmobarPP
                        { ppOutput = hPutStrLn xmproc
                        , ppTitle = xmobarColor "green" "" . shorten 50
                        }
        , terminal = "urxvt"
	, startupHook = startup
	, workspaces = myWorkspaces
        } `additionalKeys`
        [ ((controlMask, xK_Print), spawn "sleep 0.2; scrot -s")
        , ((0, xK_Print), spawn "scrot")
        ]
