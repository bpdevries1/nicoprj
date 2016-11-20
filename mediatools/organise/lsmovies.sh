rm ~/projecten/movies/movies.txt

echo Generated on: `date` >~/projecten/movies/movies.txt

# [2016-11-19 15:50] al een tijdje tijdelijk in Films-dir zelf.
# ls -lR /home/media/tijdelijk/films >>~/projecten/movies/movies.txt
ls -lR /home/media/Films >>~/projecten/movies/movies.txt

echo list of movies available in ~/projecten/movies/movies.txt

