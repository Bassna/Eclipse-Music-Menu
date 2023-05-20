from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLineEdit, QLabel, QSizePolicy, QTextEdit
from PyQt5.Qsci import QsciScintilla, QsciLexerPython
from PyQt5.QtGui import QClipboard
from PyQt5.QtCore import Qt, QTimer
import sys
import youtube_dl

class MyApp(QWidget):
    def __init__(self):
        super().__init__()

        # Set the window title
        self.setWindowTitle("Youtube Music Link Extractor")

        # Set the initial window size: width, height
        self.resize(830, 400)

        # Create the layout
        self.layout = QVBoxLayout()

        # Create the URL input box
        self.input_box = QLineEdit()
        self.layout.addWidget(self.input_box)

        # Create the extract button
        self.extract_button = QPushButton("Extract Playlist")
        self.extract_button.clicked.connect(self.extract_info)
        self.extract_button.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed)

        # Create the copy button
        self.copy_button = QPushButton("Copy Text")
        self.copy_button.clicked.connect(self.copy_text)
        self.copy_button.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed)

        # Create the help button
        self.help_button = QPushButton("?")
        self.help_button.clicked.connect(self.show_help)
        self.help_button.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed)

        # Create the copied text label
        self.copied_label = QLabel("")
        self.copied_label.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)

        # Create a horizontal layout for the buttons and label
        self.button_layout = QHBoxLayout()
        self.button_layout.addWidget(self.extract_button)
        self.button_layout.addWidget(self.copy_button)
     
        self.button_layout.addWidget(self.copied_label)
        self.button_layout.addWidget(self.help_button)
        # Add the horizontal layout to the main layout
        self.layout.addLayout(self.button_layout)

        # Create the editor
        self.editor = QsciScintilla()

        # Disable the margin (line number area)
        self.editor.setMarginWidth(1,0)

        # Enable multi-line editing (also known as rectangular selection or column mode)
        self.editor.SendScintilla(QsciScintilla.SCI_SETMULTIPLESELECTION, 1)
        self.editor.SendScintilla(QsciScintilla.SCI_SETMULTIPASTE, 1)
        self.editor.SendScintilla(QsciScintilla.SCI_SETADDITIONALSELECTIONTYPING, 1)

        self.layout.addWidget(self.editor)

        # Set the layout
        self.setLayout(self.layout)

    def extract_info(self):
        ydl_opts = {
            'extract_flat': 'in_playlist',
            'skip_download': True,
            'quiet': True,
        }

        playlist_url = self.input_box.text()

        try:
            with youtube_dl.YoutubeDL(ydl_opts) as ydl:
                playlist = ydl.extract_info(playlist_url, download=False)
        except Exception as e:
            print(f"An error occurred while extracting playlist info: {str(e)}")
            return

        self.editor.clear()

        for video in playlist['entries']:
            title = video.get('title', 'Unknown Title')
            url = video.get('url', 'Unknown URL')
            self.editor.append(f"{title}, https://www.youtube.com/watch?v={url}\n")

    def copy_text(self):
        clipboard = QApplication.clipboard()
        clipboard.setText(self.editor.text())

        self.copied_label.setText("Text Copied")
        QTimer.singleShot(2000, self.fade_text)

    def fade_text(self):
        self.copied_label.setText("")

    def show_help(self):
        self.help_window = QWidget()
        self.help_window.setWindowTitle("Help")
        self.help_window.resize(400, 300)
        layout = QVBoxLayout()
        help_text = QTextEdit()
        help_text.setReadOnly(True)
        help_text.setPlainText("Enter a Youtube Playlist into the search bar. Hit Extract Playlist. \n\n"
                               "Use Shift+Alt and select multiple lines to edit multiple lines at once.\n\n"
                               "Make sure all lines have the format \"Artist, Album, Song, Link\"")
        layout.addWidget(help_text)
        self.help_window.setLayout(layout)
        self.help_window.show()


app = QApplication(sys.argv)
window = MyApp()
window.show()
sys.exit(app.exec_())
