using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace cmdline1
{
    class Program
    {
        static void Main(string[] args)
        {
            // writeCmdlineParams(args);

            // writeFiles();

            // readFiles();
            // readFiles2();

            writeTsv();
            var values = readTsv();
            writeDictList(values);

            testConversions();
            testRegexp();
        }

        static void writeCmdlineParams(string[] args)
        {
            Console.WriteLine("Number of command line parameters = {0}", args.Length);
            for (int i = 0; i < args.Length; i++)
            {
                Console.WriteLine("Args[{0}] = [{1}]", i, args[i]);
            }

            Console.WriteLine("en nu met foreach:");
            foreach (string s in args)
            {
                Console.WriteLine(s);
            }

        }

        static void writeFiles()
        {
            // These examples assume a "C:\aaa" folder on your machine.
            // You can modify the path if necessary. 

            // Example #1: Write an array of strings to a file. 
            // Create a string array that consists of three lines. 
            string[] lines = { "First line", "Second line", "Third line" };
            // WriteAllLines creates a file, writes a collection of strings to the file, 
            // and then closes the file.
            System.IO.File.WriteAllLines(@"C:\aaa\WriteLines.txt", lines);


            // Example #2: Write one string to a text file. 
            string text = "A class is the most powerful data type in C#. Like a structure, " +
                           "a class defines the data and behavior of the data type. ";
            // WriteAllText creates a file, writes the specified string to the file, 
            // and then closes the file.
            System.IO.File.WriteAllText(@"C:\aaa\WriteText.txt", text);

            // Example #3: Write only some strings in an array to a file. 
            // The using statement automatically closes the stream and calls  
            // IDisposable.Dispose on the stream object. 
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"C:\aaa\WriteLines2.txt"))
            {
                foreach (string line in lines)
                {
                    // If the line doesn't contain the word 'Second', write the line to the file. 
                    if (!line.Contains("Second"))
                    {
                        file.WriteLine(line);
                    }
                }
            }

            // Example #4: Append new text to an existing file. 
            // The using statement automatically closes the stream and calls  
            // IDisposable.Dispose on the stream object. 
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"C:\aaa\WriteLines2.txt", true))
            {
                file.WriteLine("Fourth line");
            }
        }

        static void readFiles()
        {
            // The files used in this example are created in the topic 
            // How to: Write to a Text File. You can change the path and 
            // file name to substitute text files of your own. 

            // Example #1 
            // Read the file as one string. 
            string text = System.IO.File.ReadAllText(@"C:\aaa\WriteText.txt");

            // Display the file contents to the console. Variable text is a string.
            System.Console.WriteLine("Contents of WriteText.txt = {0}", text);

            // Example #2 
            // Read each line of the file into a string array. Each element 
            // of the array is one line of the file. 
            string[] lines = System.IO.File.ReadAllLines(@"C:\aaa\WriteLines2.txt");
            // var lines = System.IO.File.ReadAllLines(@"C:\aaa\WriteLines2.txt");

            // Display the file contents by using a foreach loop.
            System.Console.WriteLine("Contents of WriteLines2.txt = ");
            foreach (string line in lines)
            {
                // Use a tab to indent each line of the file.
                Console.WriteLine("\t" + line);
            }
        }

        static void readFiles2()
        {
            int counter = 0;
            string line;

            Console.WriteLine("Reading files with readFiles2:");
            // Read the file and display it line by line.
            System.IO.StreamReader file =
                new System.IO.StreamReader(@"C:\aaa\WriteLines2.txt");
            while ((line = file.ReadLine()) != null)
            {
                System.Console.WriteLine(line);
                counter++;
            }

            file.Close();
            System.Console.WriteLine("There were {0} lines.", counter);
        }

        static void writeTsv()
        {
            string[] lines = { "Name\tValue", "name1\t+10%", "name2\t€ 1000" };
            // WriteAllLines creates a file, writes a collection of strings to the file, 
            // and then closes the file.
            System.IO.File.WriteAllLines(@"C:\aaa\testtsv.tsv", lines);

        }

        // static List<string> readTsv()
        static List<Dictionary<string,string>> readTsv()
        {
            string[] lines = System.IO.File.ReadAllLines(@"C:\aaa\testtsv.tsv");
            var result = new List<Dictionary<string,string>>();
            // var lines = System.IO.File.ReadAllLines(@"C:\aaa\WriteLines2.txt");

            // Display the file contents by using a foreach loop.
            System.Console.WriteLine("Contents of WriteLines2.txt = ");
            string[] headers = lines[0].Split('\t');
            foreach (string line in lines.Skip(1))
            {
                // Use a tab to indent each line of the file.
                Console.WriteLine("\t" + line);
                // result.Add(line);
                Dictionary<string,string> d = new Dictionary<string,string>();
                int idx = 0;
                foreach (string elt in line.Split('\t'))
                {
                    Console.WriteLine("element found in line: {0}", elt);
                    d.Add(headers[idx], elt);
                    idx++;
                }
                result.Add(d);
            }
            return result;
        }

        static void writeDictList(List<Dictionary<string, string>> values)
        {
            Console.WriteLine("Printing contents of dict list:");
            foreach (var d in values)
            {
                Console.WriteLine("New 'line' in list:");
                foreach (var k in d.Keys)
                {
                    Console.WriteLine("Value of {0}: {1}", k, d[k]);
                }

            }
        }

        static void testConversions()
        {
            string test = "10.12";
            // double testf = 12.12;
            double testf = Convert.ToDouble(test) * 1.02;
            string test2 = Convert.ToString(testf);
            // testf formatted with max 2 decimals:
            Console.WriteLine("values of test, testf and test2: {0}, {1:0.00}, {2}", test, testf, test2);

        }

        static void testRegexp()
        {
            string s = Regex.Replace("abracadabra", "abra", "zzzz"); // vervangt beide occurences.
            Console.WriteLine("regex replaced text: {0}", s);

            if (Regex.IsMatch("abracadabra", "cadx"))
            {
                Console.WriteLine("Match found!");

            }
            else
            {
                Console.WriteLine("No match found!");
            }
            var m = Regex.Match("abracadabra met 10 en meer.", @"(\d+) en");
            if (m.Success) 
            {
                Console.WriteLine("Found match: {0}", m.ToString());
                Console.WriteLine("Found match part: {0}", m.Groups[1].Value);
            }
        }
    }
}
