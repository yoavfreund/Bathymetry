"""
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**Description**

GUI application for hand editing Bathymetry data. CMeditor written by XXXX and rewritten in Python.
Brook Tozer, SIO IGPP 2018.

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Dependencies**

NumPy
Matplotlib
pylab
wxpython
gmt-pyhton

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**References**

***

***

***
Icons where designed using the Free icon Maker.
https://freeiconmaker.com/
***

***
Documentation created using Sphinx.
***

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"""

# IMPORT MODULES~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import sys
import matplotlib as mpl
mpl.use('WXAgg')
from matplotlib import pyplot as plt
import wx
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
from matplotlib.backends.backend_wxagg import NavigationToolbar2WxAgg as NavigationToolbar
import wx.py as py
import wx.lib.agw.aui as aui
from wx.lib.buttons import GenBitmapButton
import numpy as np
from numpy import size
import vtk
from vtk.wx.wxVTKRenderWindowInteractor import wxVTKRenderWindowInteractor
from vtk.util.numpy_support import vtk_to_numpy

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class PyCMeditor(wx.Frame):
    """
    Master class for program.
    Most functions are contained in this Class.
    Sets GUI display panels, sizer's and event bindings.
    Additional classes are used for "pop out" windows (Dialog boxes).
    Objects are passed between the master class and Dialog boxes.
    """

    '# %DIR CONTAINING PROGRAM ICONS'
    # gui_icons_dir = os.path.dirname(__file__) + '/icons/'
    gui_icons_dir = '/Users/brook/kite/Py-CMeditor/icons/'

    # INITALIZE GUI~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def __init__(self, *args, **kwds):
        wx.Frame.__init__(self, None, wx.ID_ANY, 'Py-CMeditor', size=(1800, 1050))

        '# %START AUI WINDOW MANAGER'
        self.mgr = aui.AuiManager()

        '# %TELL AUI WHICH FRAME TO USE'
        self.mgr.SetManagedWindow(self)

        '# %SET SPLITTER WINDOW TOGGLE IMAGES'
        images = wx.ImageList(16, 16)
        top = wx.ArtProvider.GetBitmap(wx.ART_GO_UP, wx.ART_MENU, (16, 16))
        bottom = wx.ArtProvider.GetBitmap(wx.ART_GO_DOWN, wx.ART_MENU, (16, 16))
        images.Add(top)
        images.Add(bottom)

        '# %CREATE PANEL TO FILL WITH CONTROLS'
        self.leftPanel = wx.Panel(self, wx.ID_ANY, size=(100, 1000), style=wx.SP_NOBORDER | wx.EXPAND)
        self.leftPanel.SetBackgroundColour('white')

        '# %CREATE PANEL TO FILL WITH COORDINATE INFORMATION'
        self.rightPaneltop = wx.Panel(self, -1, size=(1800, 50), style=wx.ALIGN_RIGHT)
        self.rightPaneltop.SetBackgroundColour('white')

        '# %CREATE PANEL TO FILL WITH MATPLOTLIB INTERACTIVE FIGURE (MAIN NAVIGATION FRAME)'
        self.rightPanelbottom = wx.Panel(self, -1, size=(1700, 900), style=wx.ALIGN_RIGHT)
        self.rightPanelbottom.SetBackgroundColour('white')

        '# %CREATE PANEL FOR PYTHON CONSOLE (USED FOR DEBUGGING AND CUSTOM USAGES)'
        self.ConsolePanel = wx.Panel(self, -1, size=(1800, 100), style=wx.ALIGN_LEFT | wx.BORDER_RAISED | wx.EXPAND)
        intro = "###############################################################\r" \
                "!USE import sys; then sys.Gmg.OBJECT TO ACCESS PROGRAM OBJECTS \r" \
                "ctrl+up FOR COMMAND HISTORY                                    \r" \
                "###############################################################"
        py_local = {'__app__': 'gmg Application'}
        sys.Gmg = self
        self.win = py.shell.Shell(self.ConsolePanel, -1, size=(2200, 1100), locals=py_local, introText=intro)


        '# %ADD THE PANES TO THE AUI MANAGER'
        self.mgr.AddPane(self.leftPanel, aui.AuiPaneInfo().Name('left').Left().Caption("Controls"))
        self.mgr.AddPane(self.rightPaneltop, aui.AuiPaneInfo().Name('righttop').Top())
        self.mgr.AddPane(self.rightPanelbottom, aui.AuiPaneInfo().Name('rightbottom').CenterPane())
        self.mgr.AddPane(self.ConsolePanel, aui.AuiPaneInfo().Name('console').Bottom().Caption("Console"))
        # self.mgr.GetPaneByName('console').Hide()  # HIDE PYTHON CONSOLE BY DEFAULT
        self.mgr.Update()

        '# %CREATE PROGRAM MENUBAR & TOOLBAR (PLACED AT TOP OF FRAME)'
        self.create_menu()
        self.create_toolbar()

        '# %CREATE STATUS BAR'
        self.statusbar = self.CreateStatusBar(3, style=wx.NO_BORDER)
        self.controls_button = GenBitmapButton(self.statusbar, -1, wx.Bitmap(self.gui_icons_dir + 'redock_2.png'),
                                               pos=(0, -5), style=wx.NO_BORDER)
        # self.Bind(wx.EVT_BUTTON, self.show_controls, self.controls_button)

        '# %PYTHON CONSOLE'
        self.console_button = GenBitmapButton(self.statusbar, -1, wx.Bitmap(self.gui_icons_dir + 'python_16.png'),
                                              pos=(24, -5), style=wx.NO_BORDER)
        # self.Bind(wx.EVT_BUTTON, self.show_console, self.console_button)

        self.status_text = " || Current file: %s "
        self.statusbar.SetStatusWidths([-1, -1, 1700])
        self.statusbar.SetStatusText(self.status_text, 2)
        self.statusbar.SetSize((1800, 24))

        '# %INITALISE NAV FRAME'
        self.draw_navigation_window()

        '# %SET PROGRAM STATUS'
        self.connect_mpl_events()

        '# %SET PROGRAM STATUS'
        self.saved = False

        '# %BIND PROGRAM EXIT BUTTON WITH EXIT FUNCTION'
        self.Bind(wx.EVT_CLOSE, self.on_close_button)

        '# %MAXIMIZE FRAME'
        self.Maximize(True)

    def create_menu(self):
        """# %CREATES GUI MENUBAR"""
        self.menubar = wx.MenuBar()  # MAIN MENUBAR

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        '# % FILE MENU'
        self.file = wx.Menu()  # CREATE MENUBAR ITEM

        m_open_cm_file = self.file.Append(-1, "Open \tCtrl-L", "Open")
        self.Bind(wx.EVT_MENU, self.open_cm_file, m_open_cm_file)

        self.file.AppendSeparator()

        m_exit = self.file.Append(-1, "Exit...\tCtrl-X", "Exit...")
        self.Bind(wx.EVT_MENU, self.exit, m_exit)

        self.file.AppendSeparator()

        m_3d = self.file.Append(-1, "plot\tCtrl-p", "Plot")
        self.Bind(wx.EVT_MENU, self.plot_surface, m_3d)

        self.menubar.Append(self.file, "&File") # %DRAW FILE MENU

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        '# %EDIT MENU'
        self.edit = wx.Menu()  # CREATE MENUBAR ITEM

        self.menubar.Append(self.edit, "&Edit")  # %DRAW EDIT MENU

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        '# %FIND MENU'  # CREATE MENUBAR ITEM
        self.find = wx.Menu()

        self.menubar.Append(self.find, "&Find")  # % DRAW FIND MENU

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        '# %VIEW MENU'  # CREATE MENUBAR ITEM
        self.view = wx.Menu()

        self.menubar.Append(self.view, "&View")  # % DRAW VIEW MENU

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        '# %GO MENU'  # CREATE MENUBAR ITEM
        self.go = wx.Menu()

        self.menubar.Append(self.go, "&Go")  # % DRAW GO MENU

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        '# %TOOLS MENU'  # CREATE MENUBAR ITEM
        self.tools = wx.Menu()

        self.menubar.Append(self.tools, "&Tools")  # % DRAW TOOLS MENU

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        '# %WINDOW MENU'  # CREATE MENUBAR ITEM
        self.window = wx.Menu()

        self.menubar.Append(self.window, "&Window")  # % DRAW WINDOW MENU

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        '# %SET MENUBAR'
        self.SetMenuBar(self.menubar)

    def create_toolbar(self):
        '# %TOOLBAR - (THIS IS THE ICON BAR BELOW THE MENU BAR)'
        self.toolbar = self.CreateToolBar()

        t_save_model = self.toolbar.AddTool(wx.ID_ANY, 'Load model',
                                                 wx.Bitmap(self.gui_icons_dir + 'save_24.png'))
        # self.Bind(wx.EVT_TOOL, self.save_model, t_save_model)

        t_load_model = self.toolbar.AddTool(wx.ID_ANY, 'Load model',
                                                 wx.Bitmap(self.gui_icons_dir + 'load_24.png'))
        # self.Bind(wx.EVT_TOOL, self.load_model, t_load_model)

        t_calc_model_bott = self.toolbar.AddTool(wx.ID_ANY, 'calculate-gravity',
                                                      wx.Bitmap(self.gui_icons_dir + 'G_24.png'))
        # self.Bind(wx.EVT_TOOL, self.calc_grav_switch, t_calc_model_bott)

        t_capture_coordinates = self.toolbar.AddTool(wx.ID_ANY, 't_capture_coordinates',
                                                          wx.Bitmap(self.gui_icons_dir + 'C_24.png'))
        # self.Bind(wx.EVT_TOOL, self.capture_coordinates, t_capture_coordinates)

        t_aspect_increase = self.toolbar.AddTool(wx.ID_ANY, 'aspect-ratio-up',
                                                      wx.Bitmap(self.gui_icons_dir + 'large_up_24.png'))
        self.Bind(wx.EVT_TOOL, self.aspect_increase, t_aspect_increase)

        t_aspect_decrease = self.toolbar.AddTool(wx.ID_ANY, 'aspect-ratio-down',
                                                      wx.Bitmap(self.gui_icons_dir + 'large_down_24.png'))
        self.Bind(wx.EVT_TOOL, self.aspect_decrease, t_aspect_decrease)

        t_aspect_increase2 = self.toolbar.AddTool(wx.ID_ANY, 'aspect-ratio-up-2',
                                                       wx.Bitmap(self.gui_icons_dir + 'small_up_24.png'))
        self.Bind(wx.EVT_TOOL, self.aspect_increase2, t_aspect_increase2)

        t_aspect_decrease2 = self.toolbar.AddTool(wx.ID_ANY, 'aspect-ratio-down-2',
                                                       wx.Bitmap(self.gui_icons_dir + 'small_down_24.png'))
        self.Bind(wx.EVT_TOOL, self.aspect_decrease2, t_aspect_decrease2)

        t_zoom = self.toolbar.AddTool(wx.ID_ANY, 'zoom',
                                           wx.Bitmap(self.gui_icons_dir + 'zoom_in_24.png'))
        self.Bind(wx.EVT_TOOL, self.zoom, t_zoom)

        t_zoom_out = self.toolbar.AddTool(wx.ID_ANY, 'zoom out',
                                               wx.Bitmap(self.gui_icons_dir + 'zoom_out_24.png'))
        self.Bind(wx.EVT_TOOL, self.zoom_out, t_zoom_out)

        t_full_extent = self.toolbar.AddTool(wx.ID_ANY, 'full_extent',
                                                  wx.Bitmap(self.gui_icons_dir + 'full_extent_24.png'))
        self.Bind(wx.EVT_TOOL, self.full_extent, t_full_extent, id=604)

        t_pan = self.toolbar.AddTool(wx.ID_ANY, 'pan',
                                          wx.Bitmap(self.gui_icons_dir + 'pan_24.png'))
        self.Bind(wx.EVT_TOOL, self.pan, t_pan)
        #
        # t_transparency_down = self.toolbar.AddTool(wx.ID_ANY, 'transparency_down',
        #                                                 wx.Bitmap(self.gui_icons_dir + 'large_left_24.png'))
        # self.Bind(wx.EVT_TOOL, self.transparency_decrease, t_transparency_down)
        #
        # t_transparency_up = self.toolbar.AddTool(wx.ID_ANY, 'transparency_up',
        #                                               wx.Bitmap(self.gui_icons_dir + 'large_right_24.png'))
        # self.Bind(wx.EVT_TOOL, self.transparency_increase, t_transparency_up)
        #
        self.toolbar.Realize()
        self.toolbar.SetSize((1790, 36))

    def draw_navigation_window(self):
        """# %INITALISE OBSERVED DATA AND LAYERS"""

        """# %CREATE MPL FIGURE CANVAS"""
        mpl.rcParams['toolbar'] = 'None'

        self.fig = plt.figure()  # %CREATE MPL FIGURE
        # self.fig = Basemap(projection='robin', lon_0=0.5 * (lons[0] + lons[-1]))

        self.canvas = FigureCanvas(self.rightPanelbottom, -1, self.fig)  # %CREATE FIGURE CANVAS
        self.nav_toolbar = NavigationToolbar(self.canvas)  # %CREATE NAVIGATION TOOLBAR
        self.nav_toolbar.Hide()

        '#% SET DRAW COMMAND WHICH CAN BE CALLED TO REDRAW THE FIGURE'
        self.draw = self.fig.canvas.draw

        '#% GET THE MODEL DIMENSIONS AND SAMPLE LOCATIONS'
        self.x1 = -90.
        self.x2 = 90.
        self.y1 = -180.
        self.y2 = 180.
        self.aspect = 1.
        '#% INITAISE THE MODEL PARAMETERS'
        # self.initalise_model()

        '#% DRAW MAIN PROGRAM WINDOW'
        self.draw_main_frame()

        '#% DRAW BUTTON WINDOW'
        self.draw_button_frame()

        '#%CONNECT MPL FUNCTIONS'
        # self.connect_mpl_events()

        '#% UPDATE DISPLAY'
        # self.display_info()
        self.size_handler()

        '#% REFRESH SIZER POSITIONS'
        self.Hide()
        self.Show()

    def draw_main_frame(self):
        """# %DRAW THE PROGRAM CANVASES"""

        '#% CURRENT COORDINATES'
        self.window_font = wx.Font(16, wx.DECORATIVE, wx.ITALIC, wx.NORMAL)  # % SET FONT
        '#  % SET LONGITUDE'
        self.longitude_text = wx.StaticText(self.rightPaneltop, -1, "Longitude (x):", style=wx.ALIGN_CENTER)
        self.longitude_text.SetFont(self.window_font)
        self.longitude = wx.TextCtrl(self.rightPaneltop, -1)

        '#  % SET LATITUDE'
        self.latitude_text = wx.StaticText(self.rightPaneltop, -1, "Latitude (y):")
        self.latitude_text.SetFont(self.window_font)
        self.latitude = wx.TextCtrl(self.rightPaneltop, -1)

        '#  % SET T VALUE'
        self.T_text = wx.StaticText(self.rightPaneltop, -1, "t:")
        self.T_text.SetFont(self.window_font)

        self.T = wx.TextCtrl(self.rightPaneltop, -1)

        '#%NAV CANVAS'
        self.nav_canvas = plt.subplot2grid((20, 20), (2, 2), rowspan=17, colspan=17)
        self.nav_canvas.set_xlabel("Longitude (dec. Degrees)")
        self.nav_canvas.set_ylabel("Latitude (dec. Degrees)")
        self.nav_canvas.set_xlim(-180., 180.)  # % SET X LIMITS
        self.nav_canvas.set_ylim(-90, 90.)  # % SET Y LIMITS
        self.nav_canvas.grid()
        self.fig.subplots_adjust(top=1.05, left=-0.045, right=1.02, bottom=0.02,
                                 hspace=0.5)
        self.error = 0.
        self.last_layer = 0

        '#% UPDATE INFO BAR'
        # self.display_info()

        '#%DRAW MAIN'
        self.draw()

    def draw_button_frame(self):
        """#% CREATE LEFT HAND BUTTON MENU"""

        '# %BUTTON ONE'
        self.button_one = wx.Button(self.leftPanel, -1, "B ONE")

        '# %BUTTON TWO'
        self.button_two = wx.Button(self.leftPanel, -1, "B TWO")

        '# %BUTTON THREE'
        self.button_three = wx.Button(self.leftPanel, -1, "3D Viewer")

    def size_handler(self):
        """# %CREATE AND FIT BOX SIZERS (GUI LAYOUT)"""

        ' #% ADD CURRENT COORDINATE BOXES'
        self.coordinate_box_sizer = wx.FlexGridSizer(cols=6, hgap=7, vgap=1)
        self.coordinate_box_sizer.AddMany([self.longitude_text, self.longitude, self.latitude_text, self.latitude,
                                           self.T_text, self.T])

        ' #% ADD LIVE COORDINATE DATA BOX'
        self.box_right_top = wx.BoxSizer(wx.HORIZONTAL)
        self.box_right_top.Add(self.coordinate_box_sizer, 1, wx.ALL | wx.ALIGN_RIGHT | wx.EXPAND, border=2)

        ' #% ADD MAIN COORDINATE MAP BOX'
        self.box_right_bottom = wx.BoxSizer(wx.HORIZONTAL)
        self.box_right_bottom.Add(self.canvas, 1, wx.ALL | wx.ALIGN_RIGHT | wx.EXPAND, border=2)

        '#% CREATE LAYER TREE BOX'
        self.left_box_sizer = wx.FlexGridSizer(cols=1, rows=3, hgap=8, vgap=8)
        self.left_box_sizer.AddMany([self.button_one, self.button_two, self.button_three])

        '#PLACE BOX SIZERS IN CORRECT PANELS'
        self.leftPanel.SetSizerAndFit(self.left_box_sizer)
        self.rightPaneltop.SetSizerAndFit(self.box_right_top)
        self.rightPanelbottom.SetSizerAndFit(self.box_right_bottom)
        self.rightPaneltop.SetSize(self.GetSize())
        self.rightPanelbottom.SetSize(self.GetSize())

    def connect_mpl_events(self):
        """#% CONNECT MOUSE AND EVENT BINDINGS"""
        # self.fig.canvas.mpl_connect('button_press_event', self.button_press)
        # self.fig.canvas.mpl_connect('motion_notify_event', self.move)
        # self.fig.canvas.mpl_connect('button_release_event', self.button_release)
        # self.fig.canvas.mpl_connect('key_press_event', self.key_press)
        # self.fig.canvas.mpl_connect('pick_event', self.on_pick)

        self.button_one.Bind(wx.EVT_BUTTON, self.open_cm_file)
        self.button_two.Bind(wx.EVT_BUTTON, self.open_predicted_cm_file)
        self.button_three.Bind(wx.EVT_BUTTON, self.plot_threed)

    # FIGURE DISPLAY FUNCTIONS~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def zoom(self, event):
        self.nav_toolbar.zoom()
        self.draw()

    def zoom_out(self, event):
        self.nav_toolbar.back()
        self.draw()

    def full_extent(self, event):
        """# %REDRAW MODEL FRAME WITH FULL EXTENT"""
        '#% SET CANVAS LIMITS'
        self.nav_canvas.set_xlim(self.cm[:, 1].min() - 0.2, self.cm[:, 1].max() + 0.2)
        self.nav_canvas.set_ylim(self.cm[:, 2].min() - 0.2, self.cm[:, 2].max() + 0.2)
        self.draw()

    def pan(self, event):
        """# %PAN MODEL VIEW USING MOUSE DRAG"""
        self.nav_toolbar.pan()
        self.draw()

    def aspect_increase(self, event):
        if self.aspect >= 1:
            self.aspect = self.aspect + 1
            self.set_nav_aspect()
            self.draw()
        elif 1.0 > self.aspect >= 0.1:
            self.aspect = self.aspect + 0.1
            self.set_nav_aspect()
            self.draw()
        else:
            pass

    def aspect_decrease(self, event):
        if self.aspect >= 2:
            self.aspect = self.aspect - 1
            self.set_nav_aspect()
            self.draw()
        elif 1.0 >= self.aspect >= 0.2:
            self.aspect = self.aspect - 0.1
            self.set_nav_aspect()
            self.draw()
        else:
            pass

    def aspect_increase2(self, event):
        self.aspect = self.aspect + 2
        self.set_nav_aspect()
        self.draw()

    def aspect_decrease2(self, event):
        if self.aspect >= 3:
            self.aspect = self.aspect - 2
            self.set_nav_aspect()
            self.draw()
        else:
            pass

    def set_nav_aspect(self):
        self.nav_canvas.set_aspect(self.aspect)

    # GUI INTERACTION~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def open_cm_file(self, event):
        """# %LOAD & PLOT XY DATA E.G. EQ HYPOCENTERS"""

        open_file_dialog = wx.FileDialog(self, "Open XY file", "", "", "All files (*.cm)|*.*", wx.FD_OPEN |
                                         wx.FD_FILE_MUST_EXIST)
        if open_file_dialog.ShowModal() == wx.ID_CANCEL:
            return  # %THE USER CHANGED THEIR MIND
        else:
            cm_file = open_file_dialog.GetPath()
            self.cm_filename = open_file_dialog.Filename  # % ASSIGN FILE

        try:
            self.colorbar = plt.cm.get_cmap('RdYlBu')
            self.cm = np.genfromtxt(cm_file, delimiter=' ', dtype=float, filling_values=-9999)  # % LOAD FILE
            self.cm_plot = self.nav_canvas.scatter(self.cm[:, 1], self.cm[:, 2], marker='o', s=1, c=self.cm[:, 3],
                                                   cmap=self.colorbar, label=self.cm[:, 3])

            #  % SET WINDOW DIMENSIONS TO FIT CURRENT SURVEY
            self.nav_canvas.set_xlim(self.cm[:, 1].min()-0.2, self.cm[:, 1].max()+0.2)
            self.nav_canvas.set_ylim(self.cm[:, 2].min()-0.2, self.cm[:, 2].max()+0.2)

        except IndexError:
            error_message = "ERROR IN LOADING PROCESS - FILE MUST BE ASCII SPACE DELIMITED"
            wx.MessageDialog(self, -1, error_message, "Load Error")
            raise

        self.draw()

    def open_predicted_cm_file(self, event):
        """# %LOAD & PLOT XY DATA E.G. EQ HYPOCENTERS"""

        open_file_dialog = wx.FileDialog(self, "Open XY file", "", "", "All files (*.cm)|*.*", wx.FD_OPEN |
                                         wx.FD_FILE_MUST_EXIST)
        if open_file_dialog.ShowModal() == wx.ID_CANCEL:
            return  # %THE USER CHANGED THEIR MIND
        else:
            predicted_cm_file = open_file_dialog.GetPath()
            self.predicted_cm_filename = open_file_dialog.Filename  # % ASSIGN FILE

        try:
            self.predicted_cm = np.genfromtxt(predicted_cm_file, delimiter=' ', dtype=float, filling_values=-9999)
            self.predicted_cm_plot = self.nav_canvas.scatter(self.predicted_cm[:, 1], self.predicted_cm[:, 2],
                                                             marker='o', s=0.5, c=self.predicted_cm[:, 3],
                                                             cmap=self.colorbar)

            #  % SET WINDOW DIMENSIONS TO FIT CURRENT SURVEY
            self.nav_canvas.set_xlim(self.cm[:, 1].min()-0.2, self.cm[:, 1].max()+0.2)
            self.nav_canvas.set_ylim(self.cm[:, 2].min()-0.2, self.cm[:, 2].max()+0.2)
        except IndexError:
            error_message = "ERROR IN LOADING PROCESS - FILE MUST BE ASCII SPACE DELIMITED"
            wx.MessageDialog(self, -1, error_message, "Load Error")
            raise
        self.draw()
        self.aspect = 1
        self.set_nav_aspect()
        self.draw()

    def plot_surface(self, event):
        """CREATE SURF OF XYZ POINTS"""

        def f(x, y):
            sin, cos = np.sin, np.cos
            return x + y ** 2

        x, y = np.mgrid[-7.:7.05:0.1, -5.:5.05:0.05]
        z = f(x, y)
        s = mlab.surf(x, y, z)

        # SHOW
        mlab.show()

    def button_three(self, event):
        self.plot_threed()
        #self.SetTitle("STL File Viewer: " + self.p1.filename)
        #self.statusbar.SetStatusText("Use W,S,F,R keys and mouse to interact with the model ")

    def plot_threed(self, event):
        """PLOT 3D VIEW OF DATA"""

        '#  %SET INPUT DATA'
        self.xyz = self.cm[:, 1:4]
        self.xyz = np.divide(self.xyz, (1.0, 1.0, 10000.0))  # % DIVIDE TO MAKE Z SCALE ON SAME ORDER OF MAG AS X&Z

        try:
            self.predicted_xyz = self.predicted_cm[:, 1:4]
            self.predicted_xyz = np.divide(self.predicted_xyz, (1.0, 1.0, 10000.0))
        except AttributeError:
            self.predicted_xyz = None

        '# % OPEN A WINDOW AND CREATE A RENDERER'
        self.tdv = ThreeDimViewer(self, -1, 'Modify Current Model', self.xyz, self.predicted_xyz)
        self.tdv.Show(True)

        sys.t = self.tdv

    # DOCUMENTATION~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def open_documentation(self, event):
        """# %OPENS DOCUMENTATION HTML"""
        new = 2
        doc_url = os.path.dirname(__file__) + '/docs/_build/html/manual.html'
        webbrowser.open(doc_url, new=new)

    def about_pycmeditor(self, event):
        """# %SHOW SOFTWARE INFORMATION"""
        about = "About PyCMeditor"
        dlg = wx.MessageDialog(self, about, "About", wx.OK | wx.ICON_INFORMATION)
        result = dlg.ShowModal()
        dlg.Destroy()

    def legal(self, event):
        """# %SHOW LICENCE"""
        licence = ["Copyright 2018 Brook Tozer \n\nRedistribution and use in source and binary forms, with or "
                   "without modification, are permitted provided that the following conditions are met: \n \n"
                   "1. Redistributions of source code must retain the above copyright notice, this list of conditions "
                   "and the following disclaimer. \n\n2. Redistributions in binary form must reproduce the above "
                   "copyright notice, this list of conditions and the following disclaimer in the documentation and/or "
                   "other materials provided with the distribution. \n\n3. Neither the name of the copyright holder "
                   "nor the names of its contributors may be used to endorse or promote products  derived from this "
                   "software without specific prior written permission. \n\nTHIS SOFTWARE IS PROVIDED BY THE "
                   "COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT "
                   "NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE "
                   "DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, "
                   "INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, "
                   "PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS "
                   "INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,"
                   " OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, "
                   "EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."]

        dlg = wx.MessageDialog(self, licence[0], "BSD-3-Clause Licence", wx.OK | wx.ICON_INFORMATION)
        result = dlg.ShowModal()
        dlg.Destroy()

    # EXIT FUNCTIONS~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def exit(self, event):
        """# %SHUTDOWN APP (FROM FILE MENU)"""
        dlg = wx.MessageDialog(self, "Do you really want to exit", "Confirm Exit", wx.OK | wx.CANCEL | wx.ICON_QUESTION)
        result = dlg.ShowModal()
        if result == wx.ID_OK:
            self.Destroy()
            wx.GetApp().ExitMainLoop()

    def on_close_button(self, event):
        """# %SHUTDOWN APP (X BUTTON)"""
        dlg = wx.MessageDialog(self, "Do you really want to exit", "Confirm Exit", wx.OK | wx.CANCEL | wx.ICON_QUESTION)
        result = dlg.ShowModal()
        if result == wx.ID_OK:
            self.Destroy()
            wx.GetApp().ExitMainLoop()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 3D VIEWER CLASSES
# TODO vtk.vtkRadiusOutlierRemoval

class ThreeDimViewer(wx.Frame):
    def __init__(self, parent, id, title, xyz_data_file, predicted_xyz_file):
        wx.Frame.__init__(self, None, wx.ID_ANY, '3D Viewer', size=(1500, 1100))

        '# %START AUI WINDOW MANAGER'
        self.tdv_mgr = aui.AuiManager()

        '# %TELL AUI WHICH FRAME TO USE'
        self.tdv_mgr.SetManagedWindow(self)

        '# %CREATE PANEL TO FILL WITH COORDINATE INFORMATION'
        self.tdv_top_panel = wx.Panel(self, -1, size=(1350, 1100), style=wx.ALIGN_RIGHT | wx.BORDER_RAISED | wx.EXPAND)
        self.tdv_top_panel.SetBackgroundColour('blue')

        '# %CREATE PANEL TO FILL WITH MATPLOTLIB INTERACTIVE FIGURE (MAIN NAVIGATION FRAME)'
        self.tdv_left_panel = wx.Panel(self, -1, size=(150, 1100), style=wx.ALIGN_RIGHT | wx.BORDER_RAISED)
        self.tdv_left_panel.SetBackgroundColour('grey')

        '# %ADD THE PANES TO THE AUI MANAGER'
        self.tdv_mgr.AddPane(self.tdv_top_panel, aui.AuiPaneInfo().Name('top').CenterPane())
        self.tdv_mgr.AddPane(self.tdv_left_panel, aui.AuiPaneInfo().Name('left').Left())
        self.tdv_mgr.Update()

        '# % CREATE VTK RENDER'
        self.Interactor = wxVTKRenderWindowInteractor(self.tdv_top_panel, -1)
        self.iren = self.Interactor.GetRenderWindow().GetInteractor()

        ' #% ADD RENDERER TO TOP BOX'
        self.box_top = wx.BoxSizer(wx.VERTICAL)
        self.box_top.Add(self.Interactor, 1, wx.ALIGN_CENTRE | wx.EXPAND)

        self.renderer = vtk.vtkRenderer()
        self.renderer.SetBackground(0.8, 0.8, 0.8)

        '# % ADD MOUSE INTERACTION TOOLS --------------------------------------------------------'

        '# % CREATE TOOL BUTTONS ----------------------------------------------------------------'

        '# % PICKER BUTTON'
        self.picker_button = wx.Button(self.tdv_left_panel, -1, "Picker", size=(150, 20))
        # self.button.Bind(wx.EVT_BUTTON, self.pick)

        '# % POINT SIZER SLIDER'
        self.size_text = wx.StaticText(self.tdv_left_panel, -1, "Point size", style=wx.ALIGN_CENTRE)
        self.size_slider = wx.Slider(self.tdv_left_panel, value=2.0, minValue=1.0, maxValue=10., size=(150, 20),
                                         style=wx.SL_HORIZONTAL)
        self.size_slider.Bind(wx.EVT_SLIDER, self.set_point_size)

        '# % ADD FLAG BUTTON'
        self.flag_button = wx.Button(self.tdv_left_panel, -1, "Set Flag", size=(150, 20))
        # self.button.Bind(wx.EVT_BUTTON, self.set_flag)

        '# % ADD DELAUNAY BUTTON'
        self.delaunay_button = wx.Button(self.tdv_left_panel, -1, "Grid", size=(150, 20))
        self.delaunay_button.Bind(wx.EVT_BUTTON, self.delaunay)

        '# % ADD DELAUNAY BUTTON'
        self.predicted_delaunay_button = wx.Button(self.tdv_left_panel, -1, "Grid Predicted", size=(150, 20))
        self.predicted_delaunay_button.Bind(wx.EVT_BUTTON, self.render_predicted)

        ' #% ADD CURRENT COORDINATE BOXES'
        self.left_box = wx.FlexGridSizer(cols=1, rows=7, hgap=5, vgap=5)
        self.left_box.AddMany([self.picker_button, self.size_text, self.size_slider, self.flag_button,
                               self.delaunay_button, self.predicted_delaunay_button])

        '# % RENDER THE XYZ DATA IN 3D'
        self.xyz_data_file = xyz_data_file
        self.do_render()

        '#  % MAKE THE PREDICTED XYZ DATA AN OBJECT'
        self.predicted_xyz_file = predicted_xyz_file

        '# % SET SIZERS'
        # self.tdv_sizer()

        # '# % CREATE VTK PICKER OBJECTS'
        # self.cell_picker = vtk.vtkCellPicker()
        # self.node_picker = vtk.vtkPointPicker()
        # self.cell_picker.SetTolerance(0.001)
        # self.node_picker.SetTolerance(0.001)
        #
        # self.area_picker = vtk.vtkAreaPicker()  # vtkRenderedAreaPicker?
        # self.rubber_band_style = vtk.vtkInteractorStyleRubberBandPick()

        self.base_style = vtk.vtkInteractorStyleTrackballCamera()
        self.Interactor.SetInteractorStyle(self.base_style)
        self.current_style = str('base_style')

        '# % SET VTK OBSERVERS'
        self.Interactor.AddObserver("KeyPressEvent", self.keyPressEvent)

        '# % SET PICKER STYLE - SO LEFT MOUSE CLICK ALLOWS SELECTION OF A SINGLE POINT'
        # self.picker_style = MouseInteractorHighLightActor(self.renderWindow, self.pointcloud)
        # self.picker_style.SetDefaultRenderer(self.renderer)
        # self.Interactor.SetInteractorStyle(self.picker_style)
        # self.Interactor.AddObserver("LeftButtonPressEvent", self.picker_style.leftButtonPressEvent)        self.area_picker = vtk.vtkAreaPicker()

        '#PLACE BOX SIZERS IN CORRECT PANELS'
        self.tdv_top_panel.SetSizerAndFit(self.box_top)
        self.tdv_left_panel.SetSizerAndFit(self.left_box)
        self.tdv_top_panel.SetSize(self.GetSize())
        self.tdv_left_panel.SetSize(self.GetSize())

        self.tdv_mgr.Update()

    def do_render(self):
        """
        # % RENDER 3D POINTS
        *** arg1 = XYZ NUMPY ARRAY
        """

        '  # %Render XYZ POINTS'
        self.pointcloud = VtkPointCloud(self.xyz_data_file)
        for k in range(size(self.xyz_data_file, 0)):
            point = self.xyz_data_file[k]
            self.pointcloud.addPoint(point)

        self.renderer.AddActor(self.pointcloud.vtkActor)

        '# % Render Window'
        # self.renderer.ResetCamera()
        self.renderWindow = vtk.vtkRenderWindow()
        self.renderWindow.AddRenderer(self.renderer)
        self.Interactor.SetRenderWindow(self.renderWindow)

        '# % Add 3D AXES'
        self.axesactor = vtk.vtkAxesActor()
        self.axes = vtk.vtkOrientationMarkerWidget()
        self.axes.SetOrientationMarker(self.axesactor)
        self.axes.SetInteractor(self.iren)
        self.axes.EnabledOn()
        self.axes.InteractiveOn()
        self.renderer.ResetCamera()

        '#  % CREATE SCALE BAR'
        self.cb_mapper = self.pointcloud.vtkActor.GetMapper()
        self.cb_mapper.SetScalarRange(self.xyz_data_file[:,2].min(), self.xyz_data_file[:,2].max())
        self.sb = vtk.vtkScalarBarActor()
        self.sb.SetLookupTable(self.cb_mapper.GetLookupTable())
        self.renderer.AddActor(self.sb)
        self.sb.SetOrientationToHorizontal()
        self.sb.SetWidth(0.3)
        self.sb.SetHeight(0.05)
        self.sb.GetPositionCoordinate().SetValue(0.7, 0.05)

        self.outlineMapper = self.pointcloud.vtkActor.GetMapper()
        # self.outlineMapper.SetScalarRange
        self.outlineActor = vtk.vtkCubeAxesActor()
        self.outlineActor.SetBounds(self.xyz_data_file[:, 0].min(), self.xyz_data_file[:, 0].max(),
                                    self.xyz_data_file[:, 1].min(), self.xyz_data_file[:, 1].max(),
                                    self.xyz_data_file[:, 2].min(), self.xyz_data_file[:, 2].max())

        self.outlineActor.SetCamera(self.renderer.GetActiveCamera())
        self.outlineActor.SetMapper(self.outlineMapper)
        self.outlineActor.DrawXGridlinesOn()
        self.outlineActor.DrawYGridlinesOn()
        self.outlineActor.DrawZGridlinesOn()

        self.renderer.AddActor(self.outlineActor)

    def keyPressEvent(self, obj, event):
        key = self.Interactor.GetKeyCode()

        '''# %ACTIVATE POINT PICKER'''
        if key == 'r':
            self.rubber_picker()

    def set_point_size(self, value):
        self.size = float(self.size_slider.GetValue())
        self.pointcloud.vtkActor.GetProperty().SetPointSize(self.size)
        self.pointcloud.vtkActor.Modified()
        self.renderWindow.Render()
        return

    def delaunay(self, event):

        try:
            if self.meshActor.GetVisibility() == 1:
                self.meshActor.SetVisibility(False)
            else:
                self.meshActor.SetVisibility(True)
            self.renderWindow.Render()
            print("meshActor exists")
        except AttributeError:
            self.cell_array = vtk.vtkCellArray()
            self.boundary = self.pointcloud.vtkPolyData
            self.boundary.SetPoints(self.pointcloud.vtkPolyData.GetPoints())
            self.boundary.SetPolys(self.cell_array)

            self.delaunay = vtk.vtkDelaunay2D()
            if vtk.VTK_MAJOR_VERSION <= 5:
                self.delaunay.SetInput(self.pointcloud.vtkPolyData.GetOutput())
                self.delaunay.SetSource(self.boundary)
            else:
                self.delaunay.SetInputData(self.pointcloud.vtkPolyData)
                self.delaunay.SetSourceData(self.boundary)

            self.delaunay.Update()

            self.meshMapper = vtk.vtkPolyDataMapper()
            self.meshMapper.SetInputData(self.pointcloud.vtkPolyData)
            self.meshMapper.SetColorModeToDefault()
            self.meshMapper.SetScalarRange(self.xyz_data_file[:, 2].min(), self.xyz_data_file[:, 2].max())
            self.meshMapper.SetScalarVisibility(1)
            self.meshMapper.SetInputConnection(self.delaunay.GetOutputPort())
            self.meshActor = vtk.vtkActor()
            self.meshActor.SetMapper(self.meshMapper)
            # self.meshActor.GetProperty().SetEdgeColor(0, 0, 1)
            self.meshActor.GetProperty().SetInterpolationToFlat()
            # self.meshActor.GetProperty().SetRepresentationToWireframe()

            self.renderer.AddActor(self.meshActor)
            self.renderWindow.Render()

    def render_predicted(self, event):

        if self.predicted_xyz_file is not None:
            '  # %Render XYZ POINTS'
            self.predicted_pointcloud = VtkPointCloud(self.predicted_xyz_file)
            for k in range(size(self.predicted_xyz_file, 0)):
                point = self.predicted_xyz_file[k]
                self.predicted_pointcloud.addPoint(point)

            # self.renderer.AddActor(self.predicted_pointcloud.vtkActor)

            self.delaunay_predicted()

            self.renderWindow.Render()

    def delaunay_predicted(self):

        try:
            if self.predicted_meshActor.GetVisibility() == 1:
                self.predicted_meshActor.SetVisibility(False)
            else:
                self.predicted_meshActor.SetVisibility(True)
            self.renderWindow.Render()
            print("predicted_meshActor exists")
        except AttributeError:
            self.cell_array = vtk.vtkCellArray()
            self.boundary = self.predicted_pointcloud.vtkPolyData
            self.boundary.SetPoints(self.predicted_pointcloud.vtkPolyData.GetPoints())
            self.boundary.SetPolys(self.cell_array)

            self.delaunay = vtk.vtkDelaunay2D()
            if vtk.VTK_MAJOR_VERSION <= 5:
                self.delaunay.SetInput(self.predicted_pointcloud.vtkPolyData.GetOutput())
                self.delaunay.SetSource(self.boundary)
            else:
                self.delaunay.SetInputData(self.predicted_pointcloud.vtkPolyData)
                self.delaunay.SetSourceData(self.boundary)

            self.delaunay.Update()

            self.meshMapper = vtk.vtkPolyDataMapper()
            self.meshMapper.SetInputData(self.predicted_pointcloud.vtkPolyData)
            self.meshMapper.SetColorModeToDefault()
            self.meshMapper.SetScalarRange(self.predicted_xyz_file[:, 2].min(), self.predicted_xyz_file[:, 2].max())
            self.meshMapper.SetScalarVisibility(1)
            self.meshMapper.SetInputConnection(self.delaunay.GetOutputPort())
            self.predicted_meshActor = vtk.vtkActor()
            self.predicted_meshActor.SetMapper(self.meshMapper)
            self.predicted_meshActor.GetProperty().SetInterpolationToFlat()

            self.renderer.AddActor(self.predicted_meshActor)
            self.renderWindow.Render()

    def rubber_picker(self):
        print("r key pressed")
        print("current style = %s" % self.current_style)
        if self.current_style is 'rubber_band':
            print('setting style as base_style')
            self.base_style = vtk.vtkInteractorStyleTrackballCamera()
            self.Interactor.SetInteractorStyle(self.base_style)
            self.current_style = str('base_style')

            '# % REMOVE THE CURRENT HIGHLIGHT ACTOR (IF THERE IS ONE) FROM SCREEN'
            if self.rubber_style.selected_actor:
                self.renderer.RemoveActor(self.rubber_style.selected_actor)
                del self.rubber_style.selected_actor
                self.renderWindow.Render()
            else:
                pass
        else:
            print('setting style as rubber_band')
            self.area_picker = vtk.vtkAreaPicker()
            self.Interactor.SetPicker(self.area_picker)
            self.rubber_style = RubberBand(self.renderWindow, self.renderer, self.pointcloud, self.Interactor,
                                           self.area_picker)
            self.Interactor.SetInteractorStyle(self.rubber_style)
            self.current_style = str('rubber_band')

    # def tdv_sizer(self):
    #     """# %CREATE AND FIT BOX SIZERS"""
    #     pass

    # def middleButtonPressEvent(self, obj, event):
    #     print("Middle Button pressed")
    #     self.OnMiddleButtonDown()
    #     return
    #
    # def middleButtonReleaseEvent(self, obj, event):
    #     print("Middle Button released")
    #     self.OnMiddleButtonUp()
    #     return
    #
    # def transformPolyData(actor):
    #     polyData = vtk.vtkPolyData()
    #     polyData.DeepCopy(actor.GetMapper().GetInput())
    #     transform = vtk.vtkTransform()
    #     transform.SetMatrix(actor.GetMatrix())
    #     fil = vtk.vtkTransformPolyDataFilter()
    #     fil.SetTransform(transform)
    #     fil.SetInputDataObject(polyData)
    #     fil.Update()
    #     polyData.DeepCopy(fil.GetOutput())
    #     return polyData;
    #
    # def onKeyPressEvent(self, event):
    #     key = self.GetKeyCode()
    #     if (key == 'd'):
    #         print("d key was pressed")

class VtkPointCloud:
    def __init__(self, xyz_data_file, maxNumPoints=1e6):
        self.xyz_data_file = xyz_data_file
        self.maxNumPoints = maxNumPoints

        '# % SET COLOR MAPPER'
        self.vtkPolyData = vtk.vtkPolyData()
        self.clearPoints()
        self.mapper = vtk.vtkPolyDataMapper()
        self.mapper.SetInputData(self.vtkPolyData)
        self.mapper.SetColorModeToDefault()
        self.mapper.SetScalarRange(self.xyz_data_file[:, 2].min(), self.xyz_data_file[:, 2].max())
        self.mapper.SetScalarVisibility(1)
        self.vtkActor = vtk.vtkActor()
        self.vtkActor.SetMapper(self.mapper)

    def addPoint(self, point):
        if self.xyz_points.GetNumberOfPoints() < self.maxNumPoints:
            pointId = self.xyz_points.InsertNextPoint(point[:])
            self.xyz_depth.InsertNextValue(point[2])
            self.xyz_cells.InsertNextCell(1)
            self.xyz_cells.InsertCellPoint(pointId)
        else:
            return

    def clearPoints(self):
        self.xyz_points = vtk.vtkPoints()
        self.xyz_cells = vtk.vtkCellArray()
        self.xyz_depth = vtk.vtkDoubleArray()
        self.xyz_depth.SetName('DepthArray')
        self.vtkPolyData.SetPoints(self.xyz_points)
        self.vtkPolyData.SetVerts(self.xyz_cells)
        self.vtkPolyData.GetPointData().SetScalars(self.xyz_depth)
        self.vtkPolyData.GetPointData().SetActiveScalars('DepthArray')

# Define interaction style
class RubberBand(vtk.vtkInteractorStyleRubberBandPick):
    def __init__(self, renderWindow, renderer, pointcloud, interactor, area_picker):
        print("entering rubber band mode")
        # self.LastPickedActor = None
        # self.LastPickedProperty = vtk.vtkProperty()
        self.renderWindow = renderWindow
        self.renderer = renderer
        self.pointcloud = pointcloud
        self.Interactor = interactor
        self.selected_mapper = vtk.vtkDataSetMapper()
        self.selected_actor = vtk.vtkActor()
        self.selected_actor.SetMapper(self.selected_mapper)
        self.area_picker = area_picker

        '# % LINK BUTTON PRESS EVENTS'
        self.Interactor.AddObserver("LeftButtonPressEvent", self.leftButtonPressEvent)
        self.Interactor.AddObserver("LeftButtonReleaseEvent", self.LeftButtonReleaseEvent)

    #
    def leftButtonPressEvent(self, obj, event):
        print("LEFT BUTTON PRESSED")
        self.OnLeftButtonDown()
        '# % REMOVE THE CURRENT HIGHLIGHT ACTOR (IF THERE IS ONE) FROM SCREEN'
        self.renderer.RemoveActor(self.selected_actor)
        self.renderWindow.Render()

    def LeftButtonReleaseEvent(self, obj, event):
        print("LEFT BUTTON RELEASED")
        self.OnLeftButtonUp()

        self.frustum = self.area_picker.GetFrustum()

        self.extract_geometry = vtk.vtkExtractGeometry()
        self.extract_geometry.SetImplicitFunction(self.frustum)
        self.extract_geometry.SetInputData(self.pointcloud.vtkPolyData)
        self.extract_geometry.Update()

        self.glyph_filter = vtk.vtkVertexGlyphFilter()
        self.glyph_filter.SetInputConnection(self.extract_geometry.GetOutputPort())
        self.glyph_filter.Update()

        self.selected = self.glyph_filter.GetOutput()
        self.p1 = self.selected.GetNumberOfPoints()
        self.p2 = self.selected.GetNumberOfCells()
        print("Number of points = %s" % self.p1)
        print("Number of cells = %s" % self.p2)

        self.selected_mapper.SetInputData(self.selected)
        self.point_data = self.selected.GetPointData()

        # print("POINT DATA =")
        # print(self.point_data)
        #
        # print("ACTOR =")
        # print(self.selected_actor)
        self.selected_actor.GetProperty().SetColor(0.5, 0.5, 0.5) #(R,G,B)
        self.selected_actor.GetProperty().SetPointSize(10)

        self.processed_picked()

    def processed_picked(self):
        self.renderer.AddActor(self.selected_actor)
        self.renderWindow.Render()

        self.ids = vtk.vtkIdFilter()
        self.ids.SetInputData(self.selected)
        print(self.ids)

        self.cell_ids = vtk_to_numpy(self.selected.GetArray('Ids'))

        # print(self.cell_ids)
        # self.point_data
        # self.ids = vtk.vtkIdTypeArray.SafeDownCast(self.selected.GetPointData().GetArray("OriginalIds"))
        # print(self.ids)
        # self.count = self.ids.GetTypedTuple()
        # for i in range(self.ids.GetTypedTuple()):
        #     print("Id %s : %s" % (i, self.ids.GetValue(i)))

'''# %START SOFTWARE'''
if __name__ == "__main__":
    app = wx.App(False)
    fr = wx.Frame(None, title='Py-CMeditor')
    app.frame = PyCMeditor()
    app.frame.CenterOnScreen()
    app.frame.Show()
    app.MainLoop()







# class MouseInteractorHighLightActor(vtk.vtkInteractorStyleTrackballCamera):
#     def __init__(self, renderWindow, pointcloud):
#         self.LastPickedActor = None
#         self.LastPickedProperty = vtk.vtkProperty()
#         self.renderWindow = renderWindow
#         self.pointcloud = pointcloud
#
    # def leftButtonPressEvent(self, obj, event):
    #     print("LEFT BUTTON PRESSED")
    #     clickPos = self.renderWindow.GetInteractor().GetEventPosition()
    #
    #     picker = vtk.vtkPropPicker()
    #     picker.Pick(clickPos[0], clickPos[1], 0, self.GetDefaultRenderer())
    #
    #     # get the new
    #     self.NewPickedActor = picker.GetActor()
    #
    #     # If something was selected
    #     if self.NewPickedActor:
    #         # If we picked something before, reset its property
    #         print("GOT PICKACTOR")
    #         # if self.LastPickedActor:
    #         #     self.LastPickedActor.GetProperty().DeepCopy(self.LastPickedProperty)
    #
    #         # Save the property of the picked actor so that we can
    #         # restore it next time
    #         # self.LastPickedProperty.DeepCopy(self.NewPickedActor.GetProperty())
    #         # Highlight the picked actor by changing its properties
    #         #self.NewPickedActor.GetProperty().Color()
    #         self.NewPickedActor.GetProperty().SetColor(1.0, 1.0, 1.0)
    #         self.pointcloud.vtkActor.Modified()
    #         self.renderWindow.Render()
    #
    #         clickPos = self.renderWindow.GetInteractor().GetEventPosition()
    #         print(clickPos, self.GetInteractor().GetPicker().GetPointId())
    #         #self.NewPickedActor.GetProperty().SetDiffuse(1.0)
    #         #self.NewPickedActor.GetProperty().SetSpecular(0.0)
    #         # save the last picked actor
    #         # self.LastPickedActor = self.NewPickedActor
    #
    #     self.OnLeftButtonDown()
    #     self.update()
    #     # return
    #
    # def leftButtonPressEvent(self, obj, event):
    #     print("Left Button pressed")
    #
    #     self.OnLeftButtonDown()
    #     clickPos = self.renderWindow.GetInteractor().GetEventPosition()
    #     self.GetInteractor().GetPicker().Pick(self.GetInteractor().GetEventPosition()[0],
    #                                           self.GetInteractor().GetEventPosition()[1], 0,
    #                                           self.GetInteractor().GetRenderWindow().GetRenderers().GetFirstRenderer())
    #     self.GetInteractor().GetPicker().GetActor().GetProperty().SetColor(0.2, 1, 0.2)
    #     print(clickPos, self.GetInteractor().GetPicker().GetPointId())

    # def update(self):
    #     self.pointcloud.vtkActor.Modified()
    #     self.renderWindow.Render()

