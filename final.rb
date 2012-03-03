class Student
  @@name = []
  @@contact_no = []
  @@test_no = []
  @@address = []
  @@subject1 = []
  @@subject2 = []
  @@subject3 = []
  @@subject4 = []
  @@n = 0
  
    def input_data(no_of_students)
      @@n = no_of_students
      f = File.open("student","w")
        for i in no_of_students.to_i.downto 1
          p "enter NAME"
          @@name[i] = gets.chomp + ","
	  f.printf @@name[i]
	  p "enter contact_number"
          @@contact_no[i] = gets.chomp + ","
	  f.printf @@contact_no[i]
	  p "enter test_number"
          @@test_no[i] = gets.chomp + ","
	  f.printf @@test_no[i]
	  p "enter address"
          @@address[i] = gets.chomp + ","
	  f.printf @@address[i]
	  p "enter marks of subject1"
          @@subject1[i] = gets.chomp + ","
	  f.printf @@subject1[i]
          p "enter marks of subject2"
          @@subject2[i] = gets.chomp + ","
	  f.printf @@subject2[i]
          p "enter marks of subject3"
          @@subject3[i] = gets.chomp + ","
	  f.printf @@subject3[i]
	  p "enter marks of subject4"
          @@subject4[i] = gets
	  f.printf @@subject4[i] 
        end
      f.close
    end  
	  
    def student_marks_details(name_enter1)
      name_enter = name_enter1 + ","
        for i in @@n.to_i.downto 1
          if @@name[i] == name_enter then
            @@total_marks = 0
            @@total_marks = (@@subject1[i].to_i+@@subject2[i].to_i+@@subject3[i].to_i+@@subject4[i].to_i)
            return @@total_marks
	  end
	end
    end
     
    def student_result(student2)
      total_marks = student2
        if total_marks < 120 then
          result = 0
        else 
          result = 1
	end 
      return result
    end
	
    def student_details(student3,name_enter1)
      name_enter = name_enter1
        if student3.to_i == 1 then
	  name = ""
          details = ""
            array = IO.readlines("student")
            array.each do |arr|
            name = arr.split(',')[0]
              if name == name_enter then
                details << arr
              end 
            end
	  puts "#{name_enter} is pass"
          puts "details-#{details}"
        elsif student3.to_i == 0 then
          puts "#{name_enter} is fail and "
          puts "can attempt once again"
          name_enter = name_enter1 + ","
            for i in @@n.to_i.downto 1
              if @@name[i] == name_enter then
	        @@test_no[i] = @@test_no[i].to_i + 1
	        puts "enter the marks of 4 subjects of 2nd attempt"
		puts "enter subject1"
                @@subject_1 = gets
		puts "enter subject2"
                @@subject_2 = gets
		puts "enter subject3"
                @@subject_3 = gets
                puts "enter subject4"
                @@subject_4 = gets
	        next_total_marks = 0
                next_total_marks = (@@subject_1.to_i+@@subject_2.to_i+@@subject_3.to_i+@@subject_4.to_i)
                avg = @@total_marks + next_total_marks
	          if avg < 240 then
	            result = "fail"
                    puts "total marks of 1st attempt:"
	            puts @@total_marks
                    puts "toal marks of 2nd attempt:"
	            puts next_total_marks
	            puts " not elligle for further study"
                    name = ""
                    details = ""
                      array = IO.readlines("student")
                      array.each do |arr|
                      name = arr.split(',')[0]
                        if name == name_enter1 then
		          details << arr
                        end 
                      end 
	            puts "#{name_enter} is fail"
                    puts "details-#{details}"
		  else
	            result = "pass"
		    name = ""
                    details = ""
                      array = IO.readlines("student")
                      array.each do |arr|
                      name = arr.split(',')[0]
                        if name == name_enter1 then
                          details << arr
                        end 
                      end
	            puts "#{name_enter} is pass"
                    puts "total marks of 1st attempt:"
                    puts @@total_marks
	            puts "toal marks of 2nd attempt:"
	            puts next_total_marks
                    puts "details-#{details}"
	          end
	      end
	    end		
        end
    end        
  
  puts "enter no of students "
  no_of_students=gets.chomp + ","
  student1 = Student.new.input_data(no_of_students)
  printf "enter the name of the student to find details\n"
  name_enter1 = gets.chomp 
  student2 = Student.new.student_marks_details(name_enter1)
  student3 = Student.new.student_result(student2)
  student4 = Student.new.student_details(student3,name_enter1)
end
