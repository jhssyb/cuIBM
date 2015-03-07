/***************************************************************************//**
 * \file parseBodiesFile.cu
 * \author Anush Krishnan (anush@bu.edu)
 * \brief Parses the file \a bodies.yaml to get information about immersed bodies.
 */


#include <fstream>
#include <vector>
#include <yaml-cpp/yaml.h>
#include "io.h"
#include <body.h>


/**
 * \namespace io
 * \brief Contains functions related to I/O tasks.
 */
namespace io
{

using std::string;

/**
 * \brief Overloads the operator >>. Stores information about an immersed body.
 *
 * \param node the parsed file
 * \param instance of the class \c body to be filled
 */
void parseBodiesNode(const YAML::Node &node, body &Body, parameterDB &DB)
{
	try
	{
		// read in center of rotation
		for (int i=0; i<2; i++)
			node["centerRotation"][i] >> Body.X0[i];
	}
	catch(...)
	{
	}
	try
	{	
		// initial configuration
		for(int i=0; i<2; i++)
		{
			node["initialOffset"][i] >> Body.Xc0[i];
			Body.Xc[i] = Body.Xc0[i];
		}
	}
	catch(...)
	{
	}
	try
	{
		// initial angle of attack
		node["angleOfAttack"] >> Body.Theta0;
		Body.Theta0 *= M_PI/180.0;
		Body.Theta = Body.Theta0;
	}
	catch(...)
	{
	}
	try
	{
		// moving flags
		for (int i=0; i<2; i++)
			node["moving"][i] >> Body.moving[i];
	}
	catch(...)
	{
	}
	try
	{
		// velocity
		for (int i=0; i<2; i++)
			node["velocity"][i] >> Body.velocity[i];
	}
	catch(...)
	{
	}
	try
	{
		// omega
		node["omega"] >> Body.omega;
	}
	catch(...)
	{
	}
	try
	{
		// oscillation in X
		for (int i=0; i<3; i++)
			node["xOscillation"][i] >> Body.xOscillation[i];
		Body.xOscillation[1] *= 2*M_PI;
	}
	catch(...)
	{
	}
	try
	{
		// oscillation in Y
		for (int i=0; i<3; i++)
			node["yOscillation"][i] >> Body.yOscillation[i];
		Body.yOscillation[1] *= 2*M_PI;
	}
	catch(...)
	{
	}
	try
	{
		// pitch oscillation
		for (int i=0; i<3; i++)
			node["pitchOscillation"][i] >> Body.pitchOscillation[i];
		Body.pitchOscillation[0] *= M_PI/180.0;
		Body.pitchOscillation[1] *= 2*M_PI;
	}
	catch(...)
	{
	}

	// get the type of body and read in appropriate details
	string type;
	node["type"] >> type;
	if (type == "points")
	{
		std::string fileName;
		node["pointsFile"] >> fileName;
    std::string folderPath(DB["inputs"]["folderPath"].get<std::string>());
    std::ifstream inFile((folderPath+"/"+fileName).c_str());
    inFile >> Body.numPoints;
    Body.X.resize(Body.numPoints);
    Body.Y.resize(Body.numPoints);
    for (int i=0; i<Body.numPoints; i++)
      inFile >> Body.X[i] >> Body.Y[i];
    inFile.close();
	}
	else if (type == "lineSegment")
	{
		real startX, startY, endX, endY;
		int numPoints;
		node["segmentOptions"][0] >> startX;
		node["segmentOptions"][1] >> endX;
		node["segmentOptions"][2] >> startY;
		node["segmentOptions"][3] >> endY;
		node["segmentOptions"][4] >> numPoints;
		Body.numPoints = numPoints;
		// initialise line segment
	}
	else if (type == "circle")
	{
		real cx, cy, R;
		int numPoints;
		node["circleOptions"][0] >> cx;
		node["circleOptions"][1] >> cy;
		node["circleOptions"][2] >> R;
		node["circleOptions"][3] >> numPoints;
		Body.numPoints = numPoints;
		// initialise circle
		Body.X.resize(numPoints);
		Body.Y.resize(numPoints);
		for(int i=0; i<Body.numPoints; i++)
		{
			Body.X[i] = cx + R*cos(i*2*M_PI/Body.numPoints);
			Body.Y[i] = cy + R*sin(i*2*M_PI/Body.numPoints);
		}
	}
	else
		printf("[E]: unknown Body type\n");
	printf("\nnumPoints: %d\n",Body.numPoints);
}

/**
 * \brief Parses the \a bodies.yaml file and stores information about the immersed bodies.
 *
 * \param DB the database that contains the simulation parameters 
 */
void parseBodiesFile(parameterDB &DB)
{
	std::string folderPath(DB["inputs"]["caseFolder"].get<std::string>());
	if (!std::ifstream((folderPath+"/bodies.yaml").c_str()))
		return;
	std::ifstream inFile((folderPath+"/bodies.yaml").c_str());
	YAML::Parser parser(inFile);
	YAML::Node doc;
	parser.GetNextDocument(doc);
	inFile.close();
	body Body;
	std::vector<body> *B = DB["flows"]["bodies"].get<std::vector<body> *>();

	for (int i=0; i<doc.size(); i++)
	{
		Body.reset();
		parseBodiesNode(doc[i], Body, DB);
		B->push_back(Body);
	}
}

} // end namespace io
