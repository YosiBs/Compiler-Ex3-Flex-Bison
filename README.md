<h1>Compiler-Ex3-Flex-Bison</h1>
<p align="center">
  <img src="https://github.com/user-attachments/assets/729061b5-07ca-4660-a7c2-7ce8e95f6ace" alt=pic5 width="350">
</p>

<h2><img src="https://github.com/YosiBs/Gotcha-App/assets/105666011/558f0957-6604-47a4-a202-66a02a2835e7" alt=pic5 width="40" height="40"> Overview</h2>
<p>This project involves enhancing a simple compiler to support additional features, such as handling <code>int</code> and <code>double</code> types, implementing <code>for</code> loops, and supporting input and output statements. The enhancements are made using Flex and Bison.</p>
<h2><img src="https://github.com/YosiBs/Pokemon-Escape-Mobile-Game/assets/105666011/008a508e-5484-46ba-be36-ac359d603f01" alt=pic5 width="40" height="40"> Features Implemented</h2>
<ul>
    <li><strong>Support for <code>int</code> and <code>double</code> Types:</strong>
        <ul>
            <li>The compiler can now distinguish between <code>int</code> and <code>double</code> types and handle their declarations and operations accordingly.</li>
        </ul>
    </li>
    <li><strong>Implementation of <code>for</code> Loops:</strong>
        <ul>
            <li>The compiler supports <code>for</code> loops with integer variables, allowing iteration over a range of values.</li>
        </ul>
    </li>
    <li><strong>Input and Output Statements:</strong>
        <ul>
            <li>The compiler supports <code>INPUT(ID)</code> for reading values into variables and <code>OUTPUT(expression)</code> for printing values of expressions.</li>
        </ul>
    </li>
    <li><strong>Error Handling:</strong>
        <ul>
            <li>The compiler detects and reports errors for undeclared variables, re-declarations, and unsupported types.</li>
        </ul>
    </li>
</ul>

<h2><img src="https://github.com/YosiBs/Gotcha-App/assets/105666011/f09bd9dd-b5e2-4076-a617-fd71fe7deceb" alt=pic5 width="40" height="40"> Files Included</h2>
<ul>
    <li><code>gen.y</code> - Bison file for parsing and generating intermediate code.</li>
    <li><code>gen.lex</code> - Flex file for lexical analysis.</li>
    <li><code>symboltable.c</code> - Implementation of the symbol table.</li>
    <li><code>symboltable.h</code> - Header file for the symbol table.</li>
    <li><code>makefile</code> - Makefile to compile the project.</li>
    <li><code>examples/</code> - Folder containing example input files to test the compiler.</li>
</ul>



<h2><img src="https://github.com/YosiBs/Gotcha-App/assets/105666011/0c7e3507-e910-4ac4-b5e3-8c5d484fa682" alt=pic5 width="40" height="40"> Getting Started</h2>

<h3>Prerequisites</h3>
<ul>
    <li>Flex</li>
    <li>Bison</li>
    <li>GCC or any C compiler</li>
</ul>


<h3>Compilation</h3>
<p>To compile the project, run:</p>
<pre><code>make</code></pre>

<h3>Running the Compiler</h3>
<p>To run the compiler on an example file, use:</p>
<pre><code>./compiler examples/example1.txt</code></pre>
<p>Replace <code>examples/example1.txt</code> with the path to your input file.</p>


<h2>Usage</h2>

<h3>Variable Declarations</h3>
<p>The compiler supports <code>int</code> and <code>double</code> type declarations:</p>
<pre><code>int a, b, c;
double x, y, z;</code></pre>

<h3>Assignments</h3>
<p>The compiler supports assignments with expressions:</p>
<pre><code>a = 5;
b = a + 10;
x = 3.14;
y = x * 2;</code></pre>

<h3>For Loops</h3>
<p>The compiler supports <code>for</code> loops with integer variables:</p>
<pre><code>for (int i in 0..10) {
    a = a + 1;
    output(a);
}</code></pre>

<h3>Input and Output Statements</h3>
<p>The compiler supports reading input into variables and printing output:</p>
<pre><code>input(a);
output(a + b);
output(x);</code></pre>

<h3>Error Handling</h3>
<p>The compiler reports errors for:</p>
<ul>
    <li>Undeclared variables</li>
    <li>Re-declarations of variables</li>
    <li>Unsupported types in operations</li>
</ul>

<h2>Example Input</h2>
<pre><code>int a, b;
double x;
a = 5;
b = 10;
x = 3.14;

for (int i in 0..5) {
    a = a + 1;
    output(a);
}

output(x);</code></pre>

<h2>Example Output</h2>
<pre><code>    a = 5
    b = 10
    x = 3.14
L_1:
    t1 = i &lt;= 5
    ifFalse t1 goto L_2
    t2 = a + 1
    a = t2
    out a
    t3 = i + 1
    i = t3
    goto L_1
L_2:
[out] 3.14</code></pre>

<h2><img src="https://github.com/YosiBs/Gotcha-App/assets/105666011/9f5d6637-b1e1-4037-8f60-64388e5ab109" alt=pic5 width="40" height="40"> Authors</h2>
<ul>
    <li><a href="https://github.com/YosiBs">Yosi Ben Shushan</a></li>
</ul>

