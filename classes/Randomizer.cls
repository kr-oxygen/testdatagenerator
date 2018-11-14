@isTest
public class Randomizer  {
		//shows where if data should be in past, future, or present
		public enum DateDirection {
			present,
			future,
			past
		}

		//returns random Date
		public static Date getRandomDate(DateDirection dd) {
			return getRandomDatetime(dd).date();
		}

		//returns random Datetime
		public static Datetime getRandomDatetime(DateDirection dd) {
			Datetime dt = Datetime.now();

			Integer multiplier = getMultiplierDependsOnDateDirection(dd);


			dt.addDays(getRandomNumber(10 * multiplier));

			return dt;
		}

		//returns random Time
		public static Time getRandomTime(DateDirection dd) {
			Datetime dt = getRandomDatetime(DateDirection.present);

			Integer multiplier = getMultiplierDependsOnDateDirection(dd);

			dt.addMinutes(getRandomNumber(100) * multiplier);

			return dt.time();
		}

		//returns a random Integer
		public static Integer getRandomNumber(Integer size){
			Double d = math.random() * size;
			return d.intValue();
		}

		//returns a random String with size of 'len'
		public static String getRandomString(Integer len) {
			final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
			String randStr = '';
			
			while (randStr.length() < len) {
			   Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
			   randStr += chars.substring(idx, idx+1);
			}

			return randStr;
		}

		//Get's a random value from a list of strings
		public static String getRandomString(List<String> strings){
			List<Double> ranks = new List<Double>();
			Map<Double,String> rankMap = new Map<Double,String>();

			for(String s : strings){
				Boolean isDup = true;
				Double rank;

				while(isDup){
						Double x = getRandomNumber(100000);
						if(!rankMap.containsKey(x)){
							 rank = x;
							 isDup = false;
						}
				}

				ranks.add(rank);
				rankMap.put(rank,s);
			}

			ranks.sort();
			return rankMap.get(ranks.get(0));
		}

		//Returns Lorem Ipsum placeholder text.
		public static String getPlaceholderText(Integer length){
			String firstSentence = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ';
			List<String> sentenceList = new List<String>();
			sentenceList.add('Vivamus nec lacus eget massa cursus pulvinar. ');
			sentenceList.add('Morbi vel odio eget nunc auctor posuere eget eget ante. ');
			sentenceList.add('Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. ');
			sentenceList.add('Pellentesque lacus eros. ');
			sentenceList.add('Sed suscipit tristique varius. ');
			sentenceList.add('Mauris ultricies, nibh eu fermentum accumsan, justo quam pulvinar tellus, sed tempor quam eros sit amet ante. ');
			sentenceList.add('Duis mi libero, cursus nec facilisis ut, commodo eget nunc. ');
			sentenceList.add('Nulla eros augue, iaculis sed volutpat et, sagittis quis sem. ');
			sentenceList.add('Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla placerat accumsan vulputate. ');
			sentenceList.add('Fusce placerat tellus eget tellus faucibus a gravida sapien fermentum. ');

			String s = firstSentence;

			while (s.length() < length+1){
				s += getRandomString(sentenceList);
			}

			s = s.trim();

			while (s.length() >= length-1){
				s = s.substring(0,s.length()-1).trim();
			}

			s = s.substring(0,s.length()-1).trim();
			s += '.';
			return s;
		}

		private static Integer getMultiplierDependsOnDateDirection(DateDirection dd) {
			Integer multiplier;

			switch on dd {
				when future {
					multiplier = 1;
				}

				when past {
					multiplier = -1;
				}

				when present {
					multiplier = 0;
				}
			}

			return multiplier;
		}
	}