import matplotlib as mpl
mpl.use('WXAgg')
from matplotlib import pyplot as plt
import wx
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
from matplotlib.backends.backend_wxagg import NavigationToolbar2WxAgg as NavigationToolbar
import sys
# def color(elev):
"""SET COLOR FOR POINT PLOTTING"""

color_input = -(float(sys.argv[1])/10000.)
print(color_input)

cmap = plt.cm.get_cmap('RdYlBu')
norm = mpl.colors.Normalize(vmin=-10000.0, vmax=0.0)

rgb = cmap(color_input)[:3]
print(mpl.colors.rgb2hex(rgb))