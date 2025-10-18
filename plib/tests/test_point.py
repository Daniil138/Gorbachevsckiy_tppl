import pytest 
import json

from point import Point

@pytest.fixture
def points():
     return (Point(0,0),Point(2,2))



class TestPoint:


    def test_cretion(self):
        p = Point(1,2)
        assert p.x ==1 and p.y == 2
        with pytest.raises(TypeError):
                Point(1.5,1.5)

    def test_add(self, points):
         p1,p2 = points
         assert p2 + p1 == Point(2,2)

    def test_iadd(self, points):
         p1,p2 = points
         p1+=p2
         assert p1 == Point(2,2)

    def test_sub(self, points):
         p1,p2 = points
         assert p1-p2 == -Point(2,2)


    def test_isub(self, points):
         p1,p2 = points
         p1-=p2
         assert p1 == -Point(2,2)

    def test_distance(self):
         p1 = Point(0,0)
         p2 = Point(2,0)
         assert p1.to(p2) == 2 

    @pytest.mark.parametrize(
              "p1, p2, distance",
              [(Point(0,0),Point(0,10),10),
               (Point(10,0),Point(0,0),10),
               (Point(0,0),Point(1,1),1.414)]
    )
    def test_distance_all(self,p1,p2,distance):
         assert p1.to(p2) == pytest.approx(distance, 0.001)

    def test_is_centr(self, points):
         p1,p2=points
         assert p1.is_centre()
         assert not p2.is_centre()
         
    def test_eq(self,points):
        p1,p2=points
        with pytest.raises(NotImplementedError):
            p1 == "not a point"

        assert p1 == p1
        assert p1 != p2
    
    def test_from_json(self):
         p1 = Point.from_json('{"x":18,"y":20}')
         assert p1 == Point(18,20)

    def test_to_json(self,points):
        
        point = Point(10, 20)
        json_str = point.to_json()
        
        
        assert isinstance(json_str, str)
        
        
        data = json.loads(json_str)
        assert data["x"] == 10
        assert data["y"] == 20
    
    def test_str(self):
    
        point = Point(10, 20)
        result = str(point)
        
        assert result == "Point(10, 20)"
        assert isinstance(result, str)
    
    def test_repr(self):
        
        point = Point(10, 20)
        result = repr(point)
        
        assert result == "Point(10, 20)"
        assert isinstance(result, str)

         
