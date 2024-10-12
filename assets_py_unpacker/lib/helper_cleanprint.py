from threading import Lock

class OneLinePrinter():
    
    def __init__(self):
        self.__max_line : int = 0
        self.__lock : Lock = Lock()
    
    def print(self, line : str):
        self.__lock.acquire()
        self.__max_line = max(self.__max_line, len(line))
        print(line + " " * (self.__max_line - len(line)), end="\r", flush=True)
        self.__lock.release()