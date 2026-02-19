import customtkinter as ctk
import sys
import os

def resource_path(relative_path):
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

app = ctk.CTk()
app.iconbitmap(resource_path("bin\\cropped-MMICRO-1.ico"))

app.geometry("500x400")
app.title("Installation d'applications [WIN] - Script Launcher")

options = ["ViveTool", "File Type Association", "Firefox"]
vars = []

titre = ctk.CTkLabel(
    master=app,
    text=r"""
------------------------------------------------------------------------------
   _____           _       __     __                           __             
  / ___/__________(_)___  / /_   / /   ____ ___  ______  _____/ /_  ___  _____
  \__ \/ ___/ ___/ / __ \/ __/  / /   / __ `/ / / / __ \/ ___/ __ \/ _ \/ ___/
 ___/ / /__/ /  / / /_/ / /_   / /___/ /_/ / /_/ / / / / /__/ / / /  __/ /    
/____/\___/_/  /_/ .___/\__/  /_____/\__,_/\__,_/_/ /_/\___/_/ /_/\___/_/     
                /_/                                                           
------------------------------------------------------------------------------
""",
    font=("Consolas", 11),
    text_color="LightBlue",
)

titre.pack(pady=10)

for option in options:
    var = ctk.BooleanVar()
    checkbox = ctk.CTkCheckBox(master=app, text=option, variable=var, hover_color="lightblue", border_color="gray", border_width=2, corner_radius=6, )
    checkbox.pack(anchor="w", pady=5)
    vars.append(var)

app.mainloop()