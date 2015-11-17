//package test;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;

public class ReadStringFromFileLineByLine {

	public static void main(String[] args) {
		try {
			File file = new File("data.txt");
			FileReader fileReader = new FileReader(file);
			BufferedReader bufferedReader = new BufferedReader(fileReader);
			StringBuffer stringBuffer = new StringBuffer();
			String line;
			// while ((line = bufferedReader.readLine()) != null) {
			// 	stringBuffer.append(line);
			// 	stringBuffer.append("\n");
			// }
			line = bufferedReader.readLine();
			stringBuffer.append(line);
			stringBuffer.append("\n");
			fileReader.close();
			System.out.println("Contents of file:");
			System.out.println(stringBuffer.toString());
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}